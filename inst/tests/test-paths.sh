# Since test-paths.r does not run entirely we test this here manually.

fullpath() {
    cd "${1%% }"
    pwd -P
}

assert_equals() {
    let assertions++
    if [[ "$1" != "$2" ]]; then
        let failed++
        echo "[ERROR] $1 != $2 (expected)"
    else
        echo -n .
    fi
}

cd "$(dirname "$0")/../.."
wd="$(pwd -P)"

expected="$wd/inst/tests/modules"
script='inst/tests/modules/d.r'
assertions=0
failed=0

R CMD BATCH --vanilla --slave --no-restore --no-save --no-timing "$script" output.rcmd
rcmd_result="$(tail -n 1 output.rcmd)"
rm output.rcmd

rscript_result="$(Rscript --vanilla --no-restore --no-save "$script" | tail -n 1)"

assert_equals "$(fullpath "$rcmd_result")" "$expected"
assert_equals "$(fullpath "$rscript_result")" "$expected"

echo
echo "$failed/$assertions assertions failed"

if [[ $failed -ne 0 ]]; then
    exit 1
fi
