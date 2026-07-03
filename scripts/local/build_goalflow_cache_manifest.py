#!/usr/bin/env python
from __future__ import annotations

import argparse
import gzip
import pickle
from multiprocessing import Pool
from pathlib import Path
from typing import Iterable, List, Optional, TextIO, Tuple


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build a GoalFlow cache manifest.")
    parser.add_argument("--cache-path", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument(
        "--feature-name",
        default="transfuser_feature.gz",
        help="Feature cache filename expected under each token directory.",
    )
    parser.add_argument(
        "--target-name",
        default="transfuser_target.gz",
        help="Target cache filename expected under each token directory.",
    )
    parser.add_argument(
        "--validate-pickle",
        action="store_true",
        help="Open and unpickle feature/target cache files before adding a token.",
    )
    parser.add_argument(
        "--bad-output",
        type=Path,
        help="Optional TSV path for corrupt/incomplete cache entries.",
    )
    parser.add_argument(
        "--num-workers",
        type=int,
        default=1,
        help="Number of local worker processes used with --validate-pickle.",
    )
    return parser.parse_args()


def validate_pickle(path: Path) -> Optional[str]:
    if not path.is_file():
        return "missing"
    try:
        with gzip.open(path, "rb") as f:
            pickle.load(f)
    except Exception as exc:  # noqa: BLE001 - manifest generation should report all bad cache files.
        return f"{exc.__class__.__name__}: {exc}"
    return None


def write_bad(
    bad_file: Optional[TextIO],
    log_name: str,
    token: str,
    cache_file: str,
    reason: str,
) -> None:
    if bad_file is not None:
        safe_reason = reason.replace("\t", " ").replace("\n", " ")
        bad_file.write(f"{log_name}\t{token}\t{cache_file}\t{safe_reason}\n")


def iter_cache_tokens(
    cache_path: Path,
    feature_name: str,
    target_name: str,
) -> Iterable[Tuple[str, str, Path, Path]]:
    for log_path in sorted(cache_path.iterdir()):
        if not log_path.is_dir() or log_path.name.startswith("_"):
            continue
        for token_path in sorted(log_path.iterdir()):
            if not token_path.is_dir():
                continue
            yield (
                log_path.name,
                token_path.name,
                token_path / feature_name,
                token_path / target_name,
            )


def validate_token(
    item: Tuple[str, str, Path, Path],
) -> Tuple[str, str, List[Tuple[str, str]]]:
    log_name, token, feature_path, target_path = item
    errors: List[Tuple[str, str]] = []

    feature_error = validate_pickle(feature_path)
    target_error = validate_pickle(target_path)
    if feature_error:
        errors.append((feature_path.name, feature_error))
    if target_error:
        errors.append((target_path.name, target_error))

    return log_name, token, errors


def main() -> None:
    args = parse_args()
    cache_path: Path = args.cache_path
    output: Path = args.output

    if not cache_path.is_dir():
        raise FileNotFoundError(f"Cache path does not exist: {cache_path}")

    output.parent.mkdir(parents=True, exist_ok=True)
    if args.bad_output:
        args.bad_output.parent.mkdir(parents=True, exist_ok=True)

    log_count = 0
    token_count = 0
    skipped_incomplete = 0
    skipped_corrupt = 0

    token_items = list(iter_cache_tokens(cache_path, args.feature_name, args.target_name))
    log_count = len({log_name for log_name, _, _, _ in token_items})

    bad_file = args.bad_output.open("w", encoding="utf-8") if args.bad_output else None
    try:
        if bad_file is not None:
            bad_file.write("# log_name\ttoken\tcache_file\treason\n")

        with output.open("w", encoding="utf-8") as f:
            f.write("# log_name\ttoken\n")
            if args.validate_pickle:
                if args.num_workers > 1:
                    with Pool(processes=args.num_workers) as pool:
                        results = pool.imap(validate_token, token_items, chunksize=64)
                        for log_name, token, errors in results:
                            if errors:
                                skipped_corrupt += 1
                                for cache_file, reason in errors:
                                    if reason == "missing":
                                        skipped_incomplete += 1
                                    write_bad(bad_file, log_name, token, cache_file, reason)
                                continue
                            f.write(f"{log_name}\t{token}\n")
                            token_count += 1
                else:
                    for item in token_items:
                        log_name, token, errors = validate_token(item)
                        if errors:
                            skipped_corrupt += 1
                            for cache_file, reason in errors:
                                if reason == "missing":
                                    skipped_incomplete += 1
                                write_bad(bad_file, log_name, token, cache_file, reason)
                            continue
                        f.write(f"{log_name}\t{token}\n")
                        token_count += 1
            else:
                for log_name, token, feature_path, target_path in token_items:
                    has_feature = feature_path.is_file()
                    has_target = target_path.is_file()
                    if not has_feature or not has_target:
                        skipped_incomplete += 1
                        if not has_feature:
                            write_bad(bad_file, log_name, token, args.feature_name, "missing")
                        if not has_target:
                            write_bad(bad_file, log_name, token, args.target_name, "missing")
                        continue
                    f.write(f"{log_name}\t{token}\n")
                    token_count += 1
    finally:
        if bad_file is not None:
            bad_file.close()

    print(f"cache_path={cache_path}")
    print(f"manifest={output}")
    if args.bad_output:
        print(f"bad_output={args.bad_output}")
    print(f"log_dirs={log_count}")
    print(f"tokens={token_count}")
    print(f"skipped_incomplete={skipped_incomplete}")
    print(f"skipped_corrupt={skipped_corrupt}")


if __name__ == "__main__":
    main()
