# Benchmarks

Using test so we can run the benchmarks on both `vm` and `chrome`:

```shell
dart test --platform vm benchmark
dart test --platform chrome --compiler dart2js benchmark
dart test --platform chrome --compiler dart2wasm benchmark
```
