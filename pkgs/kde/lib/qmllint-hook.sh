# shellcheck shell=bash
qmlHostPathSeen=()
qmlIncludeDirs=()

qmlUnseenHostPath() {
    for pkg in "${qmlHostPathSeen[@]}"; do
        if [ "${pkg:?}" == "$1" ]; then
            return 1
        fi
    done

    qtHostPathSeen+=("$1")
    return 0
}

qmlHostPathHook() {
    qmlUnseenHostPath "$1" || return 0

    if ! [ -v qtQmlPrefix ]; then
        echo "qmlLintHook: qtQmlPrefix is unset. hint: add qt6.qtbase to buildInputs"
    fi

    local qmlDir="$1/${qtQmlPrefix:?}"
    if [ -d "$qmlDir" ]; then
        qmlIncludeDirs+=("-I $qmlDir")
    fi
}
addEnvHooks "$targetOffset" qmlHostPathHook

qmlLintCheck() {
    echo "Running qmlLintCheck"

    find "$out" -name '*.qml' | while IFS= read -r i; do
        echo "Checking QML file $i..."

        # qmllint has no "disable all lints" option, so disable them one by one
        @qmllint@ "$i" \
            --bare \
            --import warning \
            --required disable \
            --alias-cycle disable \
            --unresolved-alias disable \
            --with disable \
            --inheritance-cycle disable \
            --deprecated disable \
            --signal-handler-parameters disable \
            --missing-type disable \
            --unresolved-type disable \
            --restricted-type disable \
            --prefixed-import-type disable \
            --incompatible-type disable \
            --missing-property disable \
            --non-list-property disable \
            --read-only-property disable \
            --duplicate-property-binding disable \
            --duplicated-name disable \
            --unqualified disable \
            --unused-imports disable \
            --multiline-strings disable \
            --var-used-before-declaration disable \
            --invalid-lint-directive disable \
            --use-proper-function disable \
            --access-singleton-via-object disable \
            --top-level-component disable \
            --uncreatable-type disable \
            "${qmlIncludeDirs[@]}"
    done
}

if [ -z "${dontQmlLint-}" ]; then
    postInstallHooks+=('qmlLintCheck')
fi
