#!/usr/bin/env python3
"""
K3s AI Agent Team Orchestration Controller

This controller manages the lifecycle of AI agents:
- Receives task requests
- Determines which role (MARKETING/DEVELOPER/TESTER) is needed
- Scales the appropriate deployment
- Monitors task completion
- Scales back down

Author: Helpful Bob
Date: 2026-03-22
"""

import os
import time
import logging
from datetime import datetime
from flask import Flask, request, jsonify
from kubernetes import client, config
from kubernetes.client.rest import ApiException

# Initialize Flask app
app = Flask(__name__)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Load Kubernetes config
try:
    config.load_incluster_config()  # Running inside K8s
    logger.info("Loaded in-cluster Kubernetes config")
except:
    config.load_kube_config()  # Running locally
    logger.info("Loaded local Kubernetes config")

# K8s API clients
apps_v1 = client.AppsV1Api()
core_v1 = client.CoreV1Api()

# Role to namespace mapping
ROLE_CONFIG = {
    "MARKETING": {
        "namespace": "marketing-agents",
        "deployment": "marketing-agent",
        "default_replicas": 1
    },
    "DEVELOPER": {
        "namespace": "dev-agents",
        "deployment": "dev-agent",
        "default_replicas": 1
    },
    "TESTER": {
        "namespace": "test-agents",
        "deployment": "test-agent",
        "default_replicas": 1
    }
}

# Active tasks tracking
active_tasks = {}


def scale_deployment(role, replicas):
    """
    Scale a deployment to specified number of replicas
    
    Args:
        role (str): Agent role (MARKETING/DEVELOPER/TESTER)
        replicas (int): Target replica count
    
    Returns:
        bool: Success status
    """
    if role not in ROLE_CONFIG:
        logger.error(f"Unknown role: {role}")
        return False
    
    config = ROLE_CONFIG[role]
    namespace = config["namespace"]
    deployment_name = config["deployment"]
    
    try:
        # Get current deployment
        deployment = apps_v1.read_namespaced_deployment(
            name=deployment_name,
            namespace=namespace
        )
        
        # Update replica count
        deployment.spec.replicas = replicas
        
        # Patch the deployment
        apps_v1.patch_namespaced_deployment(
            name=deployment_name,
            namespace=namespace,
            body=deployment
        )
        
        logger.info(f"Scaled {role} agents to {replicas} replicas")
        return True
        
    except ApiException as e:
        logger.error(f"Failed to scale {role}: {e}")
        return False


def get_current_replicas(role):
    """Get current replica count for a role"""
    if role not in ROLE_CONFIG:
        return 0
    
    config = ROLE_CONFIG[role]
    try:
        deployment = apps_v1.read_namespaced_deployment(
            name=config["deployment"],
            namespace=config["namespace"]
        )
        return deployment.spec.replicas
    except ApiException:
        return 0


def get_pod_status(role):
    """Get status of pods for a role"""
    if role not in ROLE_CONFIG:
        return []
    
    config = ROLE_CONFIG[role]
    try:
        pods = core_v1.list_namespaced_pod(
            namespace=config["namespace"],
            label_selector=f"role={role.lower()}"
        )
        
        status_list = []
        for pod in pods.items:
            status_list.append({
                "name": pod.metadata.name,
                "phase": pod.status.phase,
                "ready": all(cs.ready for cs in pod.status.container_statuses or []),
                "node": pod.spec.node_name
            })
        
        return status_list
    except ApiException:
        return []


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat()
    })


@app.route('/status', methods=['GET'])
def status():
    """Get status of all agent deployments"""
    status_info = {}
    
    for role in ROLE_CONFIG.keys():
        status_info[role] = {
            "replicas": get_current_replicas(role),
            "pods": get_pod_status(role)
        }
    
    return jsonify({
        "timestamp": datetime.now().isoformat(),
        "agents": status_info,
        "active_tasks": len(active_tasks)
    })


@app.route('/task', methods=['POST'])
def submit_task():
    """
    Submit a new task for an AI agent
    
    Request body:
    {
        "role": "MARKETING",
        "task": "Analyze campaign performance",
        "replicas": 2  # optional, defaults to 1
    }
    """
    data = request.get_json()
    
    if not data or 'role' not in data or 'task' not in data:
        return jsonify({
            "error": "Missing required fields: role, task"
        }), 400
    
    role = data['role'].upper()
    task_description = data['task']
    replicas = data.get('replicas', ROLE_CONFIG.get(role, {}).get('default_replicas', 1))
    
    if role not in ROLE_CONFIG:
        return jsonify({
            "error": f"Invalid role: {role}",
            "valid_roles": list(ROLE_CONFIG.keys())
        }), 400
    
    # Generate task ID
    task_id = f"{role.lower()}-{int(time.time())}"
    
    # Scale up the deployment
    logger.info(f"Task {task_id}: Scaling {role} to {replicas} replicas")
    success = scale_deployment(role, replicas)
    
    if not success:
        return jsonify({
            "error": "Failed to scale deployment"
        }), 500
    
    # Track the task
    active_tasks[task_id] = {
        "role": role,
        "task": task_description,
        "replicas": replicas,
        "submitted_at": datetime.now().isoformat(),
        "status": "running"
    }
    
    return jsonify({
        "task_id": task_id,
        "role": role,
        "status": "submitted",
        "replicas": replicas,
        "message": f"Scaled {role} agents to {replicas} replicas"
    }), 201


@app.route('/task/<task_id>', methods=['GET'])
def get_task(task_id):
    """Get status of a specific task"""
    if task_id not in active_tasks:
        return jsonify({"error": "Task not found"}), 404
    
    task = active_tasks[task_id]
    role = task['role']
    
    # Get current pod status
    pods = get_pod_status(role)
    
    return jsonify({
        "task_id": task_id,
        "task": task,
        "pods": pods,
        "current_replicas": get_current_replicas(role)
    })


@app.route('/task/<task_id>/complete', methods=['POST'])
def complete_task(task_id):
    """Mark a task as complete and scale down"""
    if task_id not in active_tasks:
        return jsonify({"error": "Task not found"}), 404
    
    task = active_tasks[task_id]
    role = task['role']
    
    # Scale down to 0
    logger.info(f"Task {task_id}: Scaling {role} back to 0 replicas")
    success = scale_deployment(role, 0)
    
    if success:
        task['status'] = 'completed'
        task['completed_at'] = datetime.now().isoformat()
        
        return jsonify({
            "task_id": task_id,
            "status": "completed",
            "message": f"Scaled {role} agents to 0 replicas"
        })
    else:
        return jsonify({
            "error": "Failed to scale down deployment"
        }), 500


@app.route('/scale', methods=['POST'])
def manual_scale():
    """
    Manually scale a deployment
    
    Request body:
    {
        "role": "MARKETING",
        "replicas": 3
    }
    """
    data = request.get_json()
    
    if not data or 'role' not in data or 'replicas' not in data:
        return jsonify({
            "error": "Missing required fields: role, replicas"
        }), 400
    
    role = data['role'].upper()
    replicas = int(data['replicas'])
    
    if role not in ROLE_CONFIG:
        return jsonify({
            "error": f"Invalid role: {role}",
            "valid_roles": list(ROLE_CONFIG.keys())
        }), 400
    
    success = scale_deployment(role, replicas)
    
    if success:
        return jsonify({
            "role": role,
            "replicas": replicas,
            "message": f"Scaled {role} agents to {replicas} replicas"
        })
    else:
        return jsonify({
            "error": "Failed to scale deployment"
        }), 500


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)
