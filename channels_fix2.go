package main

import (
	"fmt"
	"sync"
)

const (
	NumRoutines = 3
	NumTokens   = 2
)

func main() {
	// Buffered channel for tokens (limitCh)
	limitCh := make(chan struct{}, NumTokens)
	
	// Unbuffered channel for notifications (found)
	found := make(chan int)
	
	var wg sync.WaitGroup
	
	// Start goroutines
	for i := 1; i <= NumRoutines; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			
			// Wait for initialization signal (in real TLA+ this is await initialized[self])
			// For simplicity in Go, we just start immediately
			
			// Wait for token from limitCh (receive_channel("limitCh"))
			<-limitCh
			fmt.Printf("Goroutine %d: received token from limitCh\n", id)
			
			// Send notification to found channel (send_unbuffered("found"))
			found <- id
			fmt.Printf("Goroutine %d: sent to found channel\n", id)
		}(i)
	}
	
	// Main process: send tokens to limitCh
	for i := 1; i <= NumRoutines; i++ {
		limitCh <- struct{}{}
		fmt.Printf("Main: sent token %d\n", i)
	}
	
	// Main process: receive from found channel
	for i := 1; i <= NumRoutines; i++ {
		id := <-found
		fmt.Printf("Main: received from found channel: %d\n", id)
	}
	
	wg.Wait()
	fmt.Println("All goroutines completed")
}
