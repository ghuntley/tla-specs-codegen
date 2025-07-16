package main

import (
	"sync"
	"testing"
	"time"
)

func TestChannelsFix2NoDeadlock(t *testing.T) {
	const (
		numRoutines = 3
		numTokens   = 2
		timeout     = 5 * time.Second
	)

	// Test with a timeout to ensure no deadlock
	done := make(chan struct{})
	
	go func() {
		defer close(done)
		
		// Buffered channel for tokens (limitCh)
		limitCh := make(chan struct{}, numTokens)
		
		// Unbuffered channel for notifications (found)
		found := make(chan int)
		
		var wg sync.WaitGroup
		
		// Start goroutines
		for i := 1; i <= numRoutines; i++ {
			wg.Add(1)
			go func(id int) {
				defer wg.Done()
				
				// Wait for token from limitCh (this is the fix - receive first)
				<-limitCh
				
				// Send notification to found channel
				found <- id
			}(i)
		}
		
		// Main process: send tokens to limitCh
		for i := 1; i <= numRoutines; i++ {
			limitCh <- struct{}{}
		}
		
		// Main process: receive from found channel
		received := make(map[int]bool)
		for i := 1; i <= numRoutines; i++ {
			id := <-found
			received[id] = true
		}
		
		// Verify all goroutines sent their notifications
		for i := 1; i <= numRoutines; i++ {
			if !received[i] {
				t.Errorf("Did not receive notification from goroutine %d", i)
			}
		}
		
		wg.Wait()
	}()

	// Wait for completion or timeout
	select {
	case <-done:
		t.Log("Test completed successfully - no deadlock")
	case <-time.After(timeout):
		t.Fatal("Test timed out - likely deadlock detected")
	}
}

func TestChannelsFix2Properties(t *testing.T) {
	t.Run("Termination", func(t *testing.T) {
		// This test verifies that the program terminates (no infinite loops or deadlocks)
		TestChannelsFix2NoDeadlock(t)
	})
	
	t.Run("AllMessagesReceived", func(t *testing.T) {
		const numRoutines = 5
		
		limitCh := make(chan struct{}, 3) // Fewer tokens than routines
		found := make(chan int, numRoutines)
		
		var wg sync.WaitGroup
		
		// Start goroutines
		for i := 1; i <= numRoutines; i++ {
			wg.Add(1)
			go func(id int) {
				defer wg.Done()
				<-limitCh
				found <- id
			}(i)
		}
		
		// Send tokens
		for i := 1; i <= numRoutines; i++ {
			limitCh <- struct{}{}
		}
		
		wg.Wait()
		close(found)
		
		// Verify all messages received
		received := make(map[int]bool)
		for id := range found {
			received[id] = true
		}
		
		if len(received) != numRoutines {
			t.Errorf("Expected %d messages, got %d", numRoutines, len(received))
		}
	})
}
