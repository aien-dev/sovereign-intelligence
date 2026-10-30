Sovereign Intelligence alpha-20261029.1 (AienOS) for Linux arm64 with an NVIDIA GB10 (DGX Spark)

bin/aienos              the wizard and the aienos command, written in Omega
bin/aien-serve-http     the engine (Core ship/motor-l387, 59b05a71: the live 35B server's build), engine omega
share/aienos/wizard/    the Omega source of bin/aienos, file by file
share/aienos/aienos.om  the same source as one unit, in build order
share/aienos/build.sh   how bin/aienos and this bundle are built
share/aienos/model.manifest   the model the wizard downloads, with every file's SHA-256
share/aienos/aienos.desktop.in, aienos.svg   the launcher and its icon
VERSION                 hashes, compiler pin and the engine's identity
SHA256SUMS              SHA-256 of every file here (aienos verify checks them in Omega)
KEYS, LICENSE, NOTICE, HOST-DEPENDENCIES.md

Commands: aienos (the wizard), aienos doctor, aienos chat, aienos start, aienos stop,
aienos verify, aienos source, aienos about, aienos uninstall [--keep-model], aienos rollback.

There is no separate CUDA++ runtime in this bundle: the engine's GPU path is the statically
linked libomega_gpu.a, which talks to /dev/nvidiactl, /dev/nvidia0 and /dev/nvidia-uvm.
NVIDIA's kernel driver stays; the CUDA toolkit, libcuda and cuBLAS stay installed and are
never loaded.
