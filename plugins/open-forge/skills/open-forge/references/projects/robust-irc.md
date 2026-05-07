# RobustIRC

**Distributed IRC server without netsplits** — implements IRC over the RobustSession protocol, providing a consistent, split-free IRC experience. Multiple servers form a Raft consensus cluster; clients reconnect transparently if a server fails.

**Official site:** https://robustirc.net  
**Source:** https://github.com/robustirc/robustirc  
**Documentation:** https://robustirc.net/docs/  
**License:** BSD-3-Clause

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux | Go binary | Primary install method |
| Any | Docker | No official image; community deployments exist |

---

## System Requirements

- Go toolchain (to build from source)
- Minimum 3 nodes for a fault-tolerant cluster (Raft requires quorum)
- Clients must use a RobustIRC-aware IRC client or bridge

---

## Inputs to Collect

### Cluster setup
| Input | Description |
|-------|-------------|
| Node addresses | Hostnames/IPs of each cluster node (minimum 3) |
| `NETWORK_NAME` | IRC network name |
| TLS certificate | TLS cert/key for each node |
| Peer authentication | Shared secret or certificate for inter-node auth |

---

## Software-layer Concerns

### Build and install
```bash
go install github.com/robustirc/robustirc@latest
```

Or clone and build:
```bash
git clone https://github.com/robustirc/robustirc
cd robustirc
go build ./...
```

### Running a node
```bash
robustirc \
  -listen=0.0.0.0:8001 \
  -peer_addr=node1.example.com:8001 \
  -join=node1.example.com:8001,node2.example.com:8001,node3.example.com:8001 \
  -network_name=MyNetwork \
  -tls_cert_path=/etc/robustirc/cert.pem \
  -tls_key_path=/etc/robustirc/key.pem
```

### IRC client usage
IRC clients need to speak the RobustSession protocol. Use:
- **RobustIRC bridge** — runs locally, presents a standard IRC interface to any IRC client
- IRC clients with native RobustSession support

See the [User Guide](https://robustirc.net/docs/) for client setup instructions.

### Key properties
- **Raft consensus** — all messages are committed to a distributed log; no single point of failure
- **No netsplits** — if a node fails, clients transparently reconnect to another node mid-session
- **Standard IRC protocol** — once connected via bridge, works with any IRC client
- **RobustSession transport** — replaces the raw TCP IRC connection with a session-based HTTP/2 protocol

---

## Upgrade Procedure

```bash
go install github.com/robustirc/robustirc@latest
# Restart each node in a rolling fashion (Raft maintains quorum during rolling restarts)
```

---

## Gotchas

- **Requires minimum 3 nodes.** A single-node deployment has no fault tolerance. 3 nodes can tolerate 1 failure; 5 nodes tolerate 2 failures.
- **Clients need a bridge or native support.** Standard IRC clients cannot connect directly to a RobustIRC server without the RobustIRC bridge.
- **Not a drop-in Ircd replacement.** RobustIRC is purpose-built for netsplit elimination and has a different operational model than traditional IRC servers (Inspircd, Unrealircd, etc.).
- **Low recent commit activity.** Check the repo for current maintenance status before deploying in production.
- **IRC feature set may differ** from traditional ircds. Consult the [User Guide](https://robustirc.net/docs/) for supported commands and features.

---

## References

- Official docs: https://robustirc.net/docs/
- Upstream README: https://github.com/robustirc/robustirc#readme
- RobustSession protocol spec: https://robustirc.net/docs/ (linked under "RobustSession protocol")
