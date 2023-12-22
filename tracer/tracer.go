package tracer

import (
	"fmt"
	"io"
	"math/rand"
	"time"

	"github.com/opentracing/opentracing-go"
	"github.com/uber/jaeger-client-go"
	"github.com/uber/jaeger-client-go/config"
)

// We can create a probabilistic sample strategy to monitor specific operations
// at defined intervals. By specifying the name and rate of the desired
// operation, we can use this strategy. The StartSpan function will adhere to
// this strategy
// example usage:
//
//	SamplingConfigs: []tracer.SamplingConfig{
//		{OperationName: "important_operation", SampleRate: 0.1}, // %10
//		{OperationName: "background_task", SampleRate: 0.5},     // %50
//	},
type SamplingConfig struct {
	OperationName string
	SampleRate    float64
}

type TracerConfig struct {
	ServiceName     string
	AgentHost       string
	SampleRate      float64
	SampleType      string
	LogSpans        bool
	SamplingConfigs []SamplingConfig
}

type Tracer struct {
	tracer opentracing.Tracer
	config TracerConfig
	closer io.Closer
}

type TracerOption func(*TracerConfig)

func WithTracerServiceName(serviceName string) TracerOption {
	return func(cfg *TracerConfig) {
		cfg.ServiceName = serviceName
	}
}

func WithTracerAgentHost(agentHost string) TracerOption {
	return func(cfg *TracerConfig) {
		cfg.AgentHost = agentHost
	}
}

func WithSampleRate(sampleRate float64) TracerOption {
	return func(cfg *TracerConfig) {
		cfg.SampleRate = sampleRate
	}
}

func WithSampleType(sampleType string) TracerOption {
	return func(cfg *TracerConfig) {
		cfg.SampleType = sampleType
	}
}

func WithLogSpans(logSpans bool) TracerOption {
	return func(cfg *TracerConfig) {
		cfg.LogSpans = logSpans
	}
}

func WithSamplingConfig(configs []SamplingConfig) TracerOption {
	return func(cfg *TracerConfig) {
		cfg.SamplingConfigs = configs
	}
}

func NewTracer(options ...TracerOption) (*Tracer, error) {
	cfg := TracerConfig{
		ServiceName: "default_service",
		AgentHost:   "localhost:6831",
		SampleRate:  1.0,
		SampleType:  "probabilistic",
	}

	for _, option := range options {
		option(&cfg)
	}

	// Jaeger configuration
	jaegerCfg := config.Configuration{
		ServiceName: cfg.ServiceName,
		Sampler: &config.SamplerConfig{
			Type:  cfg.SampleType,
			Param: cfg.SampleRate,
		},
		Reporter: &config.ReporterConfig{
			LogSpans:            cfg.LogSpans,
			BufferFlushInterval: 1 * time.Second,
			LocalAgentHostPort:  cfg.AgentHost,
		},
	}

	// Initialize tracer
	tracer, closer, err := jaegerCfg.NewTracer(
		config.Logger(jaeger.StdLogger),
	)
	if err != nil {
		return nil, fmt.Errorf("could not initialize tracer: %v", err)
	}

	opentracing.SetGlobalTracer(tracer)

	return &Tracer{
		tracer: tracer,
		config: cfg,
		closer: closer,
	}, nil
}

func (t *Tracer) StartSpan(operationName string) opentracing.Span {
	for _, samplingConfig := range t.config.SamplingConfigs {
		if samplingConfig.OperationName == operationName && rand.Float64() > samplingConfig.SampleRate {
			return nil
		}
	}

	return t.tracer.StartSpan(operationName)
}

func (t *Tracer) StartSubSpan(parent opentracing.Span, operationName string) opentracing.Span {
	if parent != nil {
		return t.tracer.StartSpan(operationName, opentracing.ChildOf(parent.Context()))
	}
	return nil
}

func (t *Tracer) FinishSpan(span opentracing.Span) {
	if span != nil {
		span.Finish()
	}
}

func (t *Tracer) Close() {
	if t.closer != nil {
		t.closer.Close()
	}
}
