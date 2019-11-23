#!/bin/bash
set -ex

echo "This is the value specified for the input 'xcresult_path': ${xcresult_path}"


# TODO: Alex - Have a check to ensure the user is on Xcode 11+ stack

# TODO: Alex - have the actual logic of extraction from xcparse here
ATTACHMENTS_OUTPUT_DIR="attachments"
ATTACHMENTS_ZIP="${ATTACHMENTS_OUTPUT_DIR}.zip"

CODECOVERAGE_OUTPUT_DIR="codecoverage"
CODECOVERAGE_ZIP="${CODECOVERAGE_OUTPUT_DIR}.zip"

LOGS_OUTPUT_DIR="logs"
LOGS_ZIP="${LOGS_OUTPUT_DIR}.zip"

SCREENSHOTS_OUTPUT_DIR="screenshots"
SCREENSHOTS_ZIP="${SCREENSHOTS_OUTPUT_DIR}.zip"


xcparse attachments "${xcresult_path}" "${ATTACHMENTS_OUTPUT_DIR}"
zip -r "${ATTACHMENTS_ZIP}" "${ATTACHMENTS_OUTPUT_DIR}"

xcparse codecov "${xcresult_path}" "${CODECOVERAGE_OUTPUT_DIR}"
zip -r "${CODECOVERAGE_ZIP}" "${CODECOVERAGE_OUTPUT_DIR}"

xcparse logs "${xcresult_path}" "${LOGS_OUTPUT_DIR}"
zip -r "${LOGS_ZIP}" "${LOGS_OUTPUT_DIR}"

xcparse screenshots "${xcresult_path}" "${SCREENSHOTS_OUTPUT_DIR}"
zip -r "${SCREENSHOTS_ZIP}" "${SCREENSHOTS_OUTPUT_DIR}"


#
# --- Export Environment Variables for other Steps:
# You can export Environment Variables for other Steps with
#  envman, which is automatically installed by `bitrise setup`.

get_abs_path() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")"; pwd -P)/$(basename "$1")"
}

envman add --key XCPARSE_VERSION --value "$(xcparse version)"

envman add --key XCPARSE_ATTACHMENTS_PATH --value $(get_abs_path ${ATTACHMENTS_ZIP})
envman add --key XCPARSE_CODE_COVERAGE_PATH --value $(get_abs_path ${CODECOVERAGE_ZIP})
envman add --key XCPARSE_LOGS_PATH --value $(get_abs_path ${LOGS_ZIP})
envman add --key XCPARSE_SCREENSHOTS_PATH --value $(get_abs_path ${SCREENSHOTS_ZIP})
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
