package global

import (
	"fmt"

	"github.com/ethereum/go-ethereum/tracer"
)

var (
	Tracer *tracer.Tracer
)

func InitGlobalTracer(host string) {
	if host == "" {
		//host = "localhost:6831"
		host = "localhost:6831"
	}
	t, err := tracer.NewTracer(
		tracer.WithTracerServiceName("geth"),
		tracer.WithTracerAgentHost(host),
		tracer.WithSampleRate(1.0),
		tracer.WithSampleType("const"),
		tracer.WithLogSpans(false),
		tracer.WithSamplingConfig([]tracer.SamplingConfig{}),
	)
	if err != nil {
		fmt.Println("Error initializing tracer:", err)
		panic(err)
	}

	Tracer = t
}
