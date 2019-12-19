# [xcparse](https://github.com/ChargePoint/xcparse)

Extract screenshots, attachments, code coverage, logs, & more from Xcode 11+ xcresult using the Swift command line tool [xcparse](https://github.com/ChargePoint/xcparse)

## Adding to your Bitrise workflow

This step is a part of Bitrise's StepLib so you can add it to your workflow by going to the Workflow Editor in [Bitrise](https://bitrise.io) and adding the step after your Xcode Test step.

![Search "xcparse" in Search Steps](Docs/Images/search_xcparse.png?raw=true)

The step should be inserted after your "Xcode Test" step or whatever step is generating your xcresult, but before your "Deploy to Bitrise.io" step.

Ensure when added that you enable "Run if previous Step failed" to ensure that your xcresult is parsed even when one of the tests in your Xcode Test step fails. Failure to do so will lead to the xcparse step being skipped if any test fails.

![Ensure to enable "Run If Previous Step Failed"](Docs/Images/enable_run_if_previous_failed.png?raw=true)

If you're not using Bitrise's Xcode Test step, update the xcresult path input variable with the path to your xcresult.

Resulting files will be placed within ZIPs that can be downloaded in your "Apps & Artifacts" tab once the build is complete. The paths to these ZIPs are provided as output variables if you want to use them directly in your other steps.

## How to use this Step

Can be run directly with the [bitrise CLI](https://github.com/bitrise-io/bitrise),
just `git clone` this repository, `cd` into it's folder in your Terminal/Command Line
and call `bitrise run test`.

*Check the `bitrise.yml` file for required inputs which have to be
added to your `.bitrise.secrets.yml` file!*

Step by step:

1. Open up your Terminal / Command Line
2. `git clone` the repository
3. `cd` into the directory of the step (the one you just `git clone`d)
5. Create a `.bitrise.secrets.yml` file in the same directory of `bitrise.yml`
   (the `.bitrise.secrets.yml` is a git ignored file, you can store your secrets in it)
6. Check the `bitrise.yml` file for any secret you should set in `.bitrise.secrets.yml`
  * Best practice is to mark these options with something like `# define these in your .bitrise.secrets.yml`, in the `app:envs` section.
7. Once you have all the required secret parameters in your `.bitrise.secrets.yml` you can just run this step with the [bitrise CLI](https://github.com/bitrise-io/bitrise): `bitrise run test`

An example `.bitrise.secrets.yml` file:

```
envs:
- A_SECRET_PARAM_ONE: the value for secret one
- A_SECRET_PARAM_TWO: the value for secret two
```

If you wish to see your UI changes while working locally, follow [this guide ](https://devcenter.bitrise.io/bitrise-cli/offline-workflow-editor/) to use the offline Workflow Editor.

## Testing your PR in Bitrise.io

If you want to test your PR changes in Bitrise.io, edit your bitrise.yml in the Workflow Editor and insert the following after your Xcode Test step but before your Deploy to Bitrise step:

```
    - git::https://github.com/ChargePoint/bitrise-step-xcparse.git@master:
        title: xcparse
```

Ensure to change the GitHub HTTPS link to your forked repo's URL & to change "master" to the name of the branch you're wanting to test.


## How to create your own step

1. Create a new git repository for your step (**don't fork** the *step template*, create a *new* repository)
2. Copy the [step template](https://github.com/bitrise-steplib/step-template) files into your repository
3. Fill the `step.sh` with your functionality
4. Wire out your inputs to `step.yml` (`inputs` section)
5. Fill out the other parts of the `step.yml` too
6. Provide test values for the inputs in the `bitrise.yml`
7. Run your step with `bitrise run test` - if it works, you're ready

__For Step development guidelines & best practices__ check this documentation: [https://github.com/bitrise-io/bitrise/blob/master/_docs/step-development-guideline.md](https://github.com/bitrise-io/bitrise/blob/master/_docs/step-development-guideline.md).

**NOTE:**

If you want to use your step in your project's `bitrise.yml`:

1. git push the step into it's repository
2. reference it in your `bitrise.yml` with the `git::PUBLIC-GIT-CLONE-URL@BRANCH` step reference style:

```
- git::https://github.com/user/my-step.git@branch:
   title: My step
   inputs:
   - my_input_1: "my value 1"
   - my_input_2: "my value 2"
```

You can find more examples of step reference styles
in the [bitrise CLI repository](https://github.com/bitrise-io/bitrise/blob/master/_examples/tutorials/steps-and-workflows/bitrise.yml#L65).

## How to contribute to this Step

1. Fork this repository
2. `git clone` it
3. Create a branch you'll work on
4. To use/test the step just follow the **How to use this Step** section
5. Do the changes you want to
6. Run/test the step before sending your contribution
  * You can also test the step in your `bitrise` project, either on your Mac or on [bitrise.io](https://www.bitrise.io)
  * You just have to replace the step ID in your project's `bitrise.yml` with either a relative path, or with a git URL format
  * (relative) path format: instead of `- original-step-id:` use `- path::./relative/path/of/script/on/your/Mac:`
  * direct git URL format: instead of `- original-step-id:` use `- git::https://github.com/user/step.git@branch:`
  * You can find more example of alternative step referencing at: https://github.com/bitrise-io/bitrise/blob/master/_examples/tutorials/steps-and-workflows/bitrise.yml
7. Once you're done just commit your changes & create a Pull Request


## Share your own Step

You can share your Step or step version with the [bitrise CLI](https://github.com/bitrise-io/bitrise). If you use the `bitrise.yml` included in this repository, all you have to do is:

1. In your Terminal / Command Line `cd` into this directory (where the `bitrise.yml` of the step is located)
1. Run: `bitrise run test` to test the step
1. Run: `bitrise run audit-this-step` to audit the `step.yml`
1. Check the `share-this-step` workflow in the `bitrise.yml`, and fill out the
   `envs` if you haven't done so already (don't forget to bump the version number if this is an update
   of your step!)
1. Then run: `bitrise run share-this-step` to share the step (version) you specified in the `envs`
1. Send the Pull Request, as described in the logs of `bitrise run share-this-step`

That's all ;)
