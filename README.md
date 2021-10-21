# spinjector
Inject Script phase in your Xcode project easily.

# How to install

```
gem install spinjector
```

# How to use
## Global configuration file
First, create a YAML configuration file under `./Configuration/spinjector_configuration.yaml` (default path where spinjector looks for a configuration file).

```
TargetNameFoo:
    - <scriptA config path> to inject
    - <scriptB config path> to inject
TargetNameBar:
    - <scriptA config path> to inject
    - <scriptC config path> to inject
```

## Script configuration file
Then, for each script you want to inject in your Xcode project, create:
- A configuration file for this script
```
name: "Hello World"                  # required. Script phase name.

# One and only one :script_path or :script may appear.
# For now, it makes no sense to have 2 differents script sources.
script_path: "Script/helloworld.sh"  # required. Script file path.
script: |                            # required. Script.
  <some code lines>
  <other code lines>

input_paths:                         # optional.
  - ""

output_paths: # optional.
  - ""

input_file_list_paths:               # optional.
  - ""

output_file_list_paths:              # optional.
  - ""

dependency_file:                     # optional.

execution_position:                  # optional. [:before-compile | :after-compile | :before-headers | :after-headers].
```

- The script file defined under `script_path` in your script configuration file
```
echo Hello World
```

## Execution
Finally, inject script phases
```
spinjector [-c] <path-to-your-global-configuration-file>
```

Enjoy your build phases
![Image of your build phases](/Examples/Images/build_phases.png)
![Image of hello world 2 build phase](/Examples/Images/hello_world_explicit.png)
