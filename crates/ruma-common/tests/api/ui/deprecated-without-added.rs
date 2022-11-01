use ruma_common::{api::Metadata, metadata};

const _: Metadata = metadata! {
    description: "This will fail.",
    method: GET,
    name: "invalid_versions",
    unstable => "/a/path",
    rate_limited: false,
    authentication: None,
    history: {
        1.1 => deprecated,
    }
};

fn main() {}