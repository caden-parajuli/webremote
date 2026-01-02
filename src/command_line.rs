use clap::Parser;
use std::net::Ipv4Addr;

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
pub struct Args {
    #[arg(short, long, default_value_t = 8080)]
    pub port: u32,
    #[arg(short, long, default_value_t=Ipv4Addr::new(127,0,0,1))]
    pub interface: Ipv4Addr,
    #[arg(short, long)]
    pub config: Option<String>,
}
pub fn parse_options() -> Args {
    Args::parse()
}
