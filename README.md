# bastard

A toy VM for learning Zig. Compiler target for future endeavors.

## goals
* stack based processing
* concurrency

## design
(/src/vm.zig)[VM]) - task scheduler

(/src/process.zig)[Process] - actually VMs, each process contains a stack and heap

(/src/engine.zig)[Engine] - interprets instructions and signals when a process should die
