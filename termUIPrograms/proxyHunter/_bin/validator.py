import sys, socket, concurrent.futures, time

def test_proxy(proxy: str, timeout_ms: int) -> bool:
    try:
        ip, port = proxy.strip().split(":")
        port_i = int(port)
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout_ms / 1000.0)
        start = time.time()
        try:
            sock.connect((ip, port_i))
            return True
        except Exception:
            return False
        finally:
            try:
                sock.close()
            except Exception:
                pass
    except Exception:
        return False

def validate_batch(proxies, timeout_ms: int, threads: int):
    good = []
    bad = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=threads) as ex:
        futs = {ex.submit(test_proxy, p, timeout_ms): p for p in proxies}
        done = 0
        total = len(futs)
        for f in concurrent.futures.as_completed(futs):
            p = futs[f]
            ok = False
            try:
                ok = f.result()
            except Exception:
                ok = False
            if ok:
                good.append(p)
            else:
                bad.append(p)
            done += 1
            # Emit progress to stdout for optional parsing
            print(f"PROGRESS {done}/{total}", flush=True)
    return good, bad

def main():
    if len(sys.argv) < 4:
        print("USAGE: validator.py <timeout_ms> <threads> <input_file>")
        sys.exit(2)
    timeout_ms = int(sys.argv[1])
    threads = int(sys.argv[2])
    input_file = sys.argv[3]
    with open(input_file, "r", encoding="utf-8", errors="ignore") as f:
        proxies = [line.strip() for line in f if line.strip()]
    good, bad = validate_batch(proxies, timeout_ms, threads)
    # Output results as simple sections
    print("GOOD_START")
    for g in good:
        print(g)
    print("GOOD_END")
    print("BAD_START")
    for b in bad:
        print(b)
    print("BAD_END")
    sys.exit(0)

if __name__ == "__main__":
    main()
