# Deciphering main.tf: Dynamic Parameters in Action

This document provides a section-by-section explanation of how `main.tf` leverages Coder's **Dynamic Parameters** to create a smart workspace provisioning flow.

## 1. The "Driver" Parameter: `tools`
**Lines 22-50**
This is the root of the dynamic logic. It uses the `multi-select` form type.
*   **`form_type = "multi-select"`**: Allows users to pick multiple items (IntelliJ, VS Code, Cursor).
*   **`type = "list(string)"`**: The value returned is a JSON-encoded list.
*   **`mutable = true`**: Users can modify this selection on an existing workspace to "add" or "remove" tools.

## 2. Aggregation Logic: `locals`
**Lines 52-71**
This section processes the selection in real-time.
*   **`selected = jsondecode(...)`**: Converts the JSON string into a Terraform list.
*   **Strategy**:
    *   **CPU (`max`)**: The heaviest IDE sets the baseline (e.g., if you pick IntelliJ and VS Code, you need at least 4 cores).
    *   **RAM/Disk (`sum`)**: Footprints stack as each IDE needs its own memory and storage.
*   **Result**: An object `local.profile` that contains the "ideal" settings for the chosen tools.

## 3. Real-time Feedback: `summary`
**Lines 76-85**
This parameter acts as an information panel.
*   It references `local.profile` in its `description`.
*   **UX Effect**: As the user clicks tools in the Coder dashboard, the description of this parameter updates instantly to show the calculated CPU/RAM/Disk requirements.

## 4. Dynamic Defaults: `cpu`, `memory`, and `disk`
**Lines 92-135**
This is the core "Dynamic" feature.
*   **`default = local.profile.cpu`**: The slider's initial position is set by the logic above.
*   **User Empowerment**: Even though the default is calculated, the user can still move the slider if they want more (or less) than the recommendation.
*   **`form_type = "slider"`**: Provides a premium, interactive feel.

## 5. Resource Implementation
**Lines 197-281**
The values are finally mapped to hardware:
*   **`coder_agent`**: Receives the values to display them in the `startup_script` and UI `metadata`.
*   **`docker_container`**: Uses the final parameter values to set `cpu_shares`, `memory` limits, and `storage_opts` (disk size).

---

## Comparison: `main.tf` vs. `official-parameters-sample.tf`

| Feature | `main.tf` | `official-parameters-sample.tf` |
| :--- | :--- | :--- |
| **Logic Type** | **Value Derivation**: Value of A sets the *default* of B. | **Visibility**: Value of A *hides/shows* B via `count`. |
| **Main UX Goal** | Automated sizing recommendations. | Branching paths / Role-based access. |
| **User Identity** | Not explicitly used for parameters. | Uses `is_admin` to hide advanced features. |
