#!/usr/bin/env bash
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# SHELLDOC-IGNORE

add_test_type revive

REVIVE_TIMER=0

REVIVE=${REVIVE:-$(command -v revive 2>/dev/null)}

function revive_usage
{
  yetus_add_option "--revive=<path>" "path to revive executable"
  yetus_add_option "--revive-config=<path>" "relative path to revive config in source tree [default: none]"
}

function revive_parse_args
{
  local i

  for i in "$@"; do
    case ${i} in
      --revive=*)
        REVIVE=${i#*=}
      ;;
      --revive-config=*)
        REVIVE_CONFIG=${i#*=}
      ;;
    esac
  done
}

function revive_filefilter
{
  local filename=$1

  if [[ ${filename} =~ \.go$ ]]; then
    add_test revive
  fi
}

function revive_precheck
{
  if ! verify_command revive "${REVIVE}"; then
    add_vote_table 0 revive "revive was not available."
    delete_test revive
  fi
}

function revive_exec
{
  declare i
  declare repostatus=$1
  declare -a args

  echo "Running revive against identified go files."
  pushd "${BASEDIR}" >/dev/null || return 1

  args=('-formatter' 'default')
  if [[ -f "${REVIVE_CONFIG}" ]]; then
    args+=('-config' "${REVIVE_CONFIG}")
  fi

  for i in "${CHANGED_FILES[@]}"; do
    if [[ ${i} =~ \.go$ && -f ${i} ]]; then
      "${REVIVE}" "${args[@]}" "${i}" 2>&1 | sort -t : -k1,1 -k2,2n -k3,3n -k 4 >> "${PATCH_DIR}/${repostatus}-revive-result.txt"
    fi
  done

  popd >/dev/null || return 1
  return 0
}

function revive_preapply
{
  declare i
  declare -a args

  if ! verify_needed_test revive; then
    return 0
  fi

  big_console_header "revive plugin: ${PATCH_BRANCH}"

  start_clock

  revive_exec branch

  REVIVE_TIMER=$(stop_clock)
  return 0
}

## @description  Wrapper to call column_calcdiffs
## @audience     private
## @stability    evolving
## @replaceable  no
## @param        branchlog
## @param        patchlog
## @return       differences
function revive_calcdiffs
{
  column_calcdiffs "$@"
}

function revive_postapply
{
  declare i
  declare numPrepatch
  declare numPostpatch
  declare diffPostpatch
  declare fixedpatch
  declare statstring

  if ! verify_needed_test revive; then
    return 0
  fi

  big_console_header "revive plugin: ${BUILDMODE}"

  start_clock

  # add our previous elapsed to our new timer
  # by setting the clock back
  offset_clock "${REVIVE_TIMER}"

  revive_exec patch

  calcdiffs \
    "${PATCH_DIR}/branch-revive-result.txt" \
    "${PATCH_DIR}/patch-revive-result.txt" \
    revive \
      > "${PATCH_DIR}/diff-patch-revive.txt"
  diffPostpatch=$("${AWK}" -F: 'BEGIN {sum=0} 3<NF {sum+=1} END {print sum}' "${PATCH_DIR}/diff-patch-revive.txt")

  # shellcheck disable=SC2016
  numPrepatch=$("${AWK}" -F: 'BEGIN {sum=0} 3<NF {sum+=1} END {print sum}' "${PATCH_DIR}/branch-revive-result.txt")

  # shellcheck disable=SC2016
  numPostpatch=$("${AWK}" -F: 'BEGIN {sum=0} 3<NF {sum+=1} END {print sum}' "${PATCH_DIR}/patch-revive-result.txt")

  ((fixedpatch=numPrepatch-numPostpatch+diffPostpatch))

  statstring=$(generic_calcdiff_status "${numPrepatch}" "${numPostpatch}" "${diffPostpatch}" )

  if [[ ${diffPostpatch} -gt 0 ]] ; then
    add_vote_table -1 revive "${BUILDMODEMSG} ${statstring}"
    add_footer_table revive "@@BASE@@/diff-patch-revive.txt"
    return 1
  elif [[ ${fixedpatch} -gt 0 ]]; then
    add_vote_table +1 revive "${BUILDMODEMSG} ${statstring}"
    return 0
  fi

  add_vote_table +1 revive "There were no new revive issues."
  return 0
}

function revive_postcompile
{
  declare repostatus=$1

  if [[ "${repostatus}" = branch ]]; then
    revive_preapply
  else
    revive_postapply
  fi
}
