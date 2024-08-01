# bastard

A toy VM for learning Zig. Compiler target for future endeavors.

## goals
* stack based processing
* concurrency

## design
[VM](src/vm.zig) - task scheduler

[Process](src/process.zig) - actually VMs, each process contains a stack and heap

[Engine](src/engine.zig) - interprets instructions and signals when a process should die
