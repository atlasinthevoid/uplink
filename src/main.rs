pub mod system;
use system::raw_log;
use system::State;
use system::init;
use system::start_game_loop;

#[async_std::main]
async fn main() {
    let mut state = State::new().await;
    raw_log("Atlas' Uplink System Core".to_string()).await;
    init(&mut state).await;
    start_game_loop(&mut state).await;
}
