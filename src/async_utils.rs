use std::time::Duration;

use tracing::{error, warn};

pub async fn retry_exponential<O, E, Fut, Args>(
    f: impl Fn(Args) -> Fut,
    args: Args,
    retries: usize,
    initial_wait: Duration,
) -> Result<O, E>
where
    Fut: Future<Output = Result<O, E>>,
    Args: std::marker::Copy,
{
    let mut wait = initial_wait;
    let mut attempt = 1;
    Ok(loop {
        match f(args).await {
            Err(err) => {
                if attempt >= retries {
                    error!("Exceeded {} tries.", retries);
                    return Err(err);
                }
                warn!("Failed. Retrying...");

                tokio::time::sleep(wait).await;

                attempt += 1;
                wait *= 2;
                continue;
            }
            Ok(client) => break client,
        }
    })
}
