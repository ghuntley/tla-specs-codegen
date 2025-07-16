package main

import (
	"fmt"
	"time"
)

type P struct {
	Name string
	ID   int
}

const concurrencyProcesses = 2

func FindAll() []P {
	// Simulate some processes
	pss := []struct{ ID int }{
		{ID: 1}, {ID: 2}, {ID: 3}, {ID: 4}, {ID: 5},
	}

	found := make(chan P)
	limitCh := make(chan struct{}, concurrencyProcesses)

	for _, pr := range pss {
		limitCh <- struct{}{}
		pr := pr
		go func() {
			defer func() { <-limitCh }()
			// Simulate some work to get a P
			time.Sleep(10 * time.Millisecond)
			p := P{Name: fmt.Sprintf("Process-%d", pr.ID), ID: pr.ID}
			found <- p
		}()
	}

	var results []P
	for p := range found {
		results = append(results, p)
	}
	return results
}

func main() {
	fmt.Println("Starting FindAll - this will deadlock...")
	results := FindAll()
	fmt.Printf("Results: %v\n", results)
}
