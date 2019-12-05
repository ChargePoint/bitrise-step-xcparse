#!/bin/bash

#=======================================
# Functions - From Bitrise's bash steps
#=======================================

RESTORE='\033[0m'
RED='\033[00;31m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
GREEN='\033[00;32m'

function color_echo {
    color=$1
    msg=$2
    echo -e "${color}${msg}${RESTORE}"
}

function echo_fail {
    msg=$1
    echo
    color_echo "${RED}" "${msg}"
    exit 1
}

function echo_warn {
    msg=$1
    color_echo "${YELLOW}" "${msg}"
}

function echo_info {
    msg=$1
    echo
    color_echo "${BLUE}" "${msg}"
}

function echo_details {
    msg=$1
    echo "  ${msg}"
}

function echo_done {
    msg=$1
    color_echo "${GREEN}" "  ${msg}"
}

function validate_required_input {
    key=$1
    value=$2
    if [ -z "${value}" ] ; then
        echo_fail "Missing required input: ${key}"
    fi
}

function validate_required_input_with_options {
    key=$1
    value=$2
    options=$3

    validate_required_input "${key}" "${value}"

    found="0"
    for option in "${options[@]}" ; do
        if [ "${option}" == "${value}" ] ; then
            found="1"
        fi
    done

    if [ "${found}" == "0" ] ; then
        echo_fail "Invalid input: (${key}) value: (${value}), valid options: ($( IFS=$", "; echo "${options[*]}" ))"
    fi
}

get_abs_path() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")"; pwd -P)/$(basename "$1")"
}

#=======================================
# Main
#=======================================
set -ex
echo "This is the value specified for the input 'xcresult_path': ${xcresult_path}"

# Check to ensure the user is on Xcode 11+ stack
if ! xcrun xcresulttool version ; then
    echo_fail "xcparse requires Xcode 11 or above to run."
fi

# We use this for validating the yes/no option input
options=("yes"  "no")

# Figure out if we want to enable verbose logging
xcparse_options=""
validate_required_input_with_options "verbose" ${verbose} "${options[@]}"
if [[ "${verbose}" == "yes" ]] ; then
    xcparse_options="-v"
fi

# Create a temporary folder
TEMPORARY_DIRECTORY="/tmp/xcparse"
rm -rf "${TEMPORARY_DIRECTORY}"
mkdir "${TEMPORARY_DIRECTORY}"

ATTACHMENTS_OUTPUT_DIR="attachments"
ATTACHMENTS_OUTPUT_PATH="${TEMPORARY_DIRECTORY}/${ATTACHMENTS_OUTPUT_DIR}"
ATTACHMENTS_ZIP="${TEMPORARY_DIRECTORY}/attachments.zip"

CODECOVERAGE_OUTPUT_DIR="codecoverage"
CODECOVERAGE_OUTPUT_PATH="${TEMPORARY_DIRECTORY}/${CODECOVERAGE_OUTPUT_DIR}"
CODECOVERAGE_ZIP="${TEMPORARY_DIRECTORY}/codecoverage.zip"

LOGS_OUTPUT_DIR="logs"
LOGS_OUTPUT_PATH="${TEMPORARY_DIRECTORY}/${LOGS_OUTPUT_DIR}"
LOGS_ZIP="${TEMPORARY_DIRECTORY}/logs.zip"

SCREENSHOTS_OUTPUT_DIR="screenshots"
SCREENSHOTS_OUTPUT_PATH="${TEMPORARY_DIRECTORY}/${SCREENSHOTS_OUTPUT_DIR}"
SCREENSHOTS_ZIP="${TEMPORARY_DIRECTORY}/screenshots.zip"

# Now let's start extraction
validate_required_input_with_options "extract_attachments" ${extract_attachments} "${options[@]}"
if [[ "${extract_attachments}" == "yes" ]] ; then
    xcparse_cmd="xcparse attachments \"${xcresult_path}\" \"${ATTACHMENTS_OUTPUT_PATH}\""
    if [[ "${xcparse_options}" != "" ]] ; then
        xcparse_cmd="${xcparse_cmd} ${xcparse_options}"
    fi

    # Check the attachments config
    if [[ "${attachments_divide_by_model}" == "yes" ]] ; then
        xcparse_cmd="${xcparse_cmd} --model"
    fi
    if [[ "${attachments_divide_by_os}" == "yes" ]] ; then
        xcparse_cmd="${xcparse_cmd} --os"
    fi
    if [[ "${attachments_divide_by_language}" == "yes" ]] ; then
        xcparse_cmd="${xcparse_cmd} --language"
    fi
    if [[ "${attachments_divide_by_region}" == "yes" ]] ; then
        xcparse_cmd="${xcparse_cmd} --region"
    fi
    if [[ "${attachments_divide_by_test_plan_config}" == "yes" ]] ; then
        xcparse_cmd="${xcparse_cmd} --test-plan-config"
    fi
    if [[ "${attachments_divide_by_test}" == "yes" ]] ; then
        xcparse_cmd="${xcparse_cmd} --test"
    fi
    if [[ "${attachments_whitelist_activity_type}" != "" ]] ; then
        xcparse_cmd="${xcparse_cmd} --activity-type ${attachments_whitelist_activity_type}"
    fi
    if [[ "${attachments_whitelist_test_status}" != "" ]] ; then
        xcparse_cmd="${xcparse_cmd} --test-status ${attachments_whitelist_test_status}"
    fi
    if [[ "${attachments_whitelist_uti}" != "" ]] ; then
        xcparse_cmd="${xcparse_cmd} --uti ${attachments_whitelist_uti}"
    fi

    # Now let's finally run this thing
    echo_details "$xcparse_cmd"
    echo
    eval "$xcparse_cmd"

    # ZIP it up
    if [ "$(ls -A $ATTACHMENTS_OUTPUT_PATH)" ]; then
        (cd "${ATTACHMENTS_OUTPUT_PATH}/.." && zip -r "${ATTACHMENTS_ZIP}" "${ATTACHMENTS_OUTPUT_DIR}")
        envman add --key XCPARSE_ATTACHMENTS_PATH --value $(get_abs_path ${ATTACHMENTS_ZIP})

        # Check to see if we need to move things over to deploy
        if [[ "${export_to_deploy}" == "yes" && ! -z "$BITRISE_DEPLOY_DIR" ]] ; then
          cp "${ATTACHMENTS_ZIP}" "${BITRISE_DEPLOY_DIR}"
        fi
    fi
fi

validate_required_input_with_options "extract_code_coverage" ${extract_code_coverage} "${options[@]}"
if [[ "${extract_code_coverage}" == "yes" ]] ; then
    if [[ "${xcparse_options}" != "" ]] ; then
        xcparse codecov ${xcparse_options} "${xcresult_path}" "${CODECOVERAGE_OUTPUT_PATH}"
    else
        xcparse codecov "${xcresult_path}" "${CODECOVERAGE_OUTPUT_PATH}"
    fi

    # ZIP it up
    if [ "$(ls -A $CODECOVERAGE_OUTPUT_PATH)" ]; then
        (cd "${CODECOVERAGE_OUTPUT_PATH}/.." && zip -r "${CODECOVERAGE_ZIP}" "${CODECOVERAGE_OUTPUT_DIR}")
        envman add --key XCPARSE_CODE_COVERAGE_PATH --value $(get_abs_path ${CODECOVERAGE_ZIP})

        # Check to see if we need to move things over to deploy
        if [[ "${export_to_deploy}" == "yes" && ! -z "$BITRISE_DEPLOY_DIR" ]] ; then
          cp "${CODECOVERAGE_ZIP}" "${BITRISE_DEPLOY_DIR}"
        fi
    fi
fi

validate_required_input_with_options "extract_logs" ${extract_logs} "${options[@]}"
if [[ "${extract_logs}" == "yes" ]] ; then
    if [[ "${xcparse_options}" != "" ]] ; then
        xcparse logs ${xcparse_options} "${xcresult_path}" "${LOGS_OUTPUT_PATH}"
    else
        xcparse logs "${xcresult_path}" "${LOGS_OUTPUT_PATH}"
    fi

    if [ "$(ls -A $LOGS_OUTPUT_PATH)" ]; then
        (cd "${LOGS_OUTPUT_PATH}/.." && zip -r "${LOGS_ZIP}" "${LOGS_OUTPUT_DIR}")
        envman add --key XCPARSE_LOGS_PATH --value $(get_abs_path ${LOGS_ZIP})

        # Check to see if we need to move things over to deploy
        if [[ "${export_to_deploy}" == "yes" && ! -z "$BITRISE_DEPLOY_DIR" ]] ; then
          cp "${LOGS_ZIP}" "${BITRISE_DEPLOY_DIR}"
        fi
    fi
fi

validate_required_input_with_options "extract_screenshots" ${extract_screenshots} "${options[@]}"
if [[ "${extract_screenshots}" == "yes" ]] ; then
    xcparse_cmd="xcparse screenshots \"${xcresult_path}\" \"${SCREENSHOTS_OUTPUT_PATH}\""
    if [[ "${xcparse_options}" != "" ]] ; then
        xcparse_cmd="${xcparse_cmd} ${xcparse_options}"
    fi

    # Check the screenshot config
    if [[ "${screenshots_divide_by_model}" == "yes" ]] ; then
        xcparse_cmd="${xcparse_cmd} --model"
    fi
    if [[ "${screenshots_divide_by_os}" == "yes" ]] ; then
        xcparse_cmd="${xcparse_cmd} --os"
    fi
    if [[ "${screenshots_divide_by_language}" == "yes" ]] ; then
        xcparse_cmd="${xcparse_cmd} --language"
    fi
    if [[ "${screenshots_divide_by_region}" == "yes" ]] ; then
        xcparse_cmd="${xcparse_cmd} --region"
    fi
    if [[ "${screenshots_divide_by_test_plan_config}" == "yes" ]] ; then
        xcparse_cmd="${xcparse_cmd} --test-plan-config"
    fi
    if [[ "${screenshots_divide_by_test}" == "yes" ]] ; then
        xcparse_cmd="${xcparse_cmd} --test"
    fi
    if [[ "${screenshots_whitelist_activity_type}" != "" ]] ; then
        xcparse_cmd="${xcparse_cmd} --activity-type ${screenshots_whitelist_activity_type}"
    fi
    if [[ "${screenshots_whitelist_test_status}" != "" ]] ; then
        xcparse_cmd="${xcparse_cmd} --test-status ${screenshots_whitelist_test_status}"
    fi

    # Now let's finally run this thing
    echo_details "$xcparse_cmd"
    echo
    eval "$xcparse_cmd"

    # ZIP it up
    if [ "$(ls -A $SCREENSHOTS_OUTPUT_PATH)" ]; then
        (cd "${SCREENSHOTS_OUTPUT_PATH}/.." && zip -r "${SCREENSHOTS_ZIP}" "${SCREENSHOTS_OUTPUT_DIR}")
        envman add --key XCPARSE_SCREENSHOTS_PATH --value $(get_abs_path ${SCREENSHOTS_ZIP})

        # Check to see if we need to move things over to deploy
        if [[ "${export_to_deploy}" == "yes" && ! -z "$BITRISE_DEPLOY_DIR" ]] ; then
          cp "${SCREENSHOTS_ZIP}" "${BITRISE_DEPLOY_DIR}"
        fi
    fi
fi


#
# --- Export Environment Variables for other Steps:
# You can export Environment Variables for other Steps with
#  envman, which is automatically installed by `bitrise setup`.

envman add --key XCPARSE_VERSION --value "$(xcparse version)"

# Envman can handle piped inputs, which is useful if the text you want to
# share is complex and you don't want to deal with proper bash escaping:
#  cat file_with_complex_input | envman add --KEY EXAMPLE_STEP_OUTPUT
# You can find more usage examples on envman's GitHub page
#  at: https://github.com/bitrise-io/envman

#
# --- Exit codes:
# The exit code of your Step is very important. If you return
#  with a 0 exit code `bitrise` will register your Step as "successful".
# Any non zero exit code will be registered as "failed" by `bitrise`.
