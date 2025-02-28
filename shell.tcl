source run.tcl

# Shell prompt
proc repl_prompt {} {
    puts -nonewline "aerialsdb> "
    flush stdout
}

# Commands executor 
proc repl_execute {command} {
    # Check if the command is 'exit'
    if {[string match "exit" $command]} {
        puts "Exiting REPL..."
        return 1  ;# breaks REPL cycle
    }

    # Execute command using eval
    try {
        eval $command
    } on error {msg} {
        puts "Error while executing: $msg"
    }

    return 0
}

# Main REPL function
proc start_repl {} {
		puts "AerialsDB shell. Type exit to leave."
    while {1} {
        repl_prompt
        set command [gets stdin]
        
        # If exit, quit REPL
        if {[repl_execute $command]} {
            break
        }
    }
}

# Let's go
start_repl
