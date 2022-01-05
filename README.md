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
scripts:
  foo:
    name: "Foo"
    script: |
      echo Foo
    execution_position: :after_compile

targets:
  TargetNameA:
    - foo
    - "helloworld.yaml"
    - "helloworld_explicit_script.yaml"
  TargetNameB:
    - "helloworld_short.yaml"
    - foo

```

## Script configuration file
Then, for each script you want to inject in your Xcode project:
- You can use `scripts` section in the global configuration file to define your script directly (eg. `foo`)...

- ...Or create a script configuration file (eg. `helloworld.yaml`)

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

execution_position:                  # optional. [:before_compile | :after_compile | :before_headers | :after_headers].
```

- If you use the `script_path option`, create the script file
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

## How to contribute

1. After all your changes are reviewed and merged
2. Create a `release` branch
3. Update the version in field `s.version` from file `spinjector.gemspec`
4. Execute `make publish`

You may need to configure your account at step `4.` if you've never pushed any gem. You can find all the informations you need on [the official documentation](https://guides.rubygems.org/make-your-own-gem/#your-first-gem).
