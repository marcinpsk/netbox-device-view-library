# netbox-device-view-library

YAML layouts and SVG artwork for the [netbox-device-view](https://github.com/peterbaumert/netbox-device-view) NetBox plugin. Add this repository as a NetBox Data Source and import the layouts into device views, and the artwork as visual definitions.

## Directory structure

The structure follows the [netbox-community devicetype-library](https://github.com/netbox-community/devicetype-library):

```text
device-types/<Manufacturer>/<part number or model>.yaml       # layouts
artwork/<Manufacturer>/<part number or model>/                # artwork definitions
├── manifest.yaml
├── front.svg
└── rear.svg
```

- `<Manufacturer>` is the exact NetBox manufacturer name, as in devicetype-library.
- The file name is the device type's part number or model, as in devicetype-library. For example, `device-types/Cisco/C8300-1N1S-6T.yaml` is the layout for the model `Catalyst 8300-1N1S-6T` with the part number `C8300-1N1S-6T`.

An artwork directory has the name of the devicetype-library file of the same type, without `.yaml`. The check finds the devicetype-library type from this path.

A layout for an installed module is a `variant` in the layout of the device type, not a separate file. The plugin selects the variant when a module of that model is installed. For this reason, the repository has no `module-types/` directory.

## Layouts

| File | Device type | Variants |
|---|---|---|
| `device-types/Avocent/ACS6048.yaml` | Avocent ACS6048 | none |
| `device-types/Cisco/C8300-1N1S-6T.yaml` | Cisco Catalyst 8300-1N1S-6T | `NIM-16A` in bay `NIM 1` |

The layouts are schematic. They show each connector at its approximate position, not the exact panel geometry.

### Known limitation: console-server ports

A layout does not bind console-server ports yet ([netbox-device-view#26](https://github.com/marcinpsk/netbox-device-view/issues/26)). The serial ports of the ACS6048 (`ttyS1` to `ttyS48`) and of the NIM-16A (`Async0/1/0` to `Async0/1/15`) show as cells, but without cable occupancy or links. Their keys use the plugin's port key format (`ttys1`, `async0-1-0`), so they bind when the plugin supports them. The ACS6048 artwork (below) binds them already.

## Artwork

| Directory | Hardware | Faces | Reference |
|---|---|---|---|
| `artwork/Avocent/ACS6048/` | Avocent ACS6048DAC-G2 (dual AC) | front, rear | Vertiv 590-1764-501A, figure 2.2, tables 2.1 and A.1 |

Each artwork definition is an original drawing from the hardware reference that its manifest names, under the MIT licence of this repository. The rear face of the ACS6048 binds the console-server ports `ttyS1` to `ttyS48`, the interfaces `eth0` and `eth1`, the console ports `console` and `aux`, and the power ports `ps1` and `ps2`. The USB port and the LEDs on the front face are decorative and have no binding.

To import the artwork, use **Plugins → Artwork Revisions → Import from Data Source** with the directory prefix `artwork/`. Then activate the revision for the device type. See the plugin's [artwork documentation](https://github.com/marcinpsk/netbox-device-view/blob/develop/docs/artwork-bundles.md).

## Import into NetBox

1. In NetBox, go to **Operations → Integrations → Data Sources** and add a Data Source:
    - **Type**: Git
    - **URL**: `https://github.com/marcinpsk/netbox-device-view-library.git`
2. Click **Sync** and wait until the status of the Data Source is **Completed**.
3. Go to **Plugins → Device Views**, click **Import from Data Source**, select the Data Source and set the directory prefix to `device-types/`.
4. To import the artwork, go to **Plugins → Artwork Revisions**, click **Import from Data Source**, select the Data Source and set the directory prefix to `artwork/`. The import stores each definition as a revision, but it does not change a device view.
5. Open each artwork revision, click **Activate** and select the device type. See the plugin's [artwork documentation](https://github.com/marcinpsk/netbox-device-view/blob/50cb378/docs/artwork-bundles.md#import-from-a-data-source).

The plugin suggests a device type when the parent directory is the manufacturer name and the file name is the model or the part number of the device type. Otherwise, select the device type manually.

The import from a Data Source is in the `main` branch of the plugin since commit [d911efb](https://github.com/peterbaumert/netbox-device-view/commit/d911efb). See the plugin's [import documentation](https://github.com/peterbaumert/netbox-device-view/blob/d911efb/docs/import-from-data-source.md).

## Add a layout

1. Write the layout in the [YAML layout format](https://github.com/marcinpsk/netbox-device-view/blob/50cb378/docs/layout-yaml.md) of the plugin.
2. Name the file like the devicetype-library file of the same device type.
3. Use the plugin's component keys: an interface `GigabitEthernet0/0/1` has the key `gigabitethernet0-1`, and a port `ttyS1` has the key `ttys1`.
4. Run the check (below).

## Add artwork

1. Draw one SVG file for each face, in the [SVG profile](https://github.com/marcinpsk/netbox-device-view/blob/50cb378/docs/artwork-bundles.md#svg-profile) of the plugin. The `viewBox` is in millimetres of the real face.
    - A device definition has a `front` face, a `rear` face or both.
    - A module definition has one `installed` face: the face that shows in the module bay.
2. Write `manifest.yaml`. Name the exact hardware SKU and the reference that you drew from. A device definition binds each connector to the exact component name of the devicetype-library type. A module definition binds each connector to the NetBox template name, for example `TenGigabitEthernet1/{module}/1`. See the [manifest rules](https://github.com/marcinpsk/netbox-device-view/blob/50cb378/docs/artwork-bundles.md#manifest) of the plugin.
3. Put the files in `artwork/<Manufacturer>/<name>/`, where `<name>` is the name of the devicetype-library file.
4. Run the check (below).
5. In the pull request, record that you compared the drawing with the reference: the chassis, and the count, type, position and label of each connector.

## Check

`scripts/check.sh` checks every layout and every artwork definition with the `device_view_check` command of the plugin. The command uses the validation code of the imports, and it checks that each artwork binding names a component of the devicetype-library type. The CI runs the same script on each pull request. The script needs Git and Docker:

```bash
scripts/check.sh
```

The script uses the plugin commit and the devicetype-library commit of the `pins/` entries. These entries are Git submodules only as pins: a clone does not need them, and the script fetches only what it needs. `.gitmodules` names the branch of each pin. Every week, Dependabot opens a pull request that moves a pin to the head of its branch. To follow another branch, change `branch` in `.gitmodules`.

The CI also audits the workflows and the Dependabot configuration with [zizmor](https://docs.zizmor.sh/). Each action is pinned to a commit hash, and Dependabot moves these pins 7 days after a release. To run the audit locally, run `zizmor .` (for example `uvx zizmor .`).
