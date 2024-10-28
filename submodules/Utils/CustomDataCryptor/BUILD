
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "CustomDataCryptor",
    module_name = "CustomDataCryptor",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
         "//submodules/Utils/PeerSecretsManager",
    ],
    visibility = [
        "//visibility:public",
    ],
)
