package main

import (
    "context"
    "crypto/tls"
    "crypto/x509"
    "fmt"
    "io/ioutil"
    "log"
    "time"

    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/attribute"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
    "go.opentelemetry.io/otel/sdk/resource"
    "go.opentelemetry.io/otel/sdk/trace"
    semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
    "google.golang.org/grpc"
    "google.golang.org/grpc/credentials"
)

func main() {
    // Load client certificates
    clientCert, err := tls.LoadX509KeyPair("../certs/client-cert.pem", "../certs/client-key.pem")
    if err != nil {
        log.Fatalf("Failed to load client certificates: %v", err)
    }

    // Load CA certificate
    caCert, err := ioutil.ReadFile("../certs/ca.pem")
    if err != nil {
        log.Fatalf("Failed to read CA certificate: %v", err)
    }

    caCertPool := x509.NewCertPool()
    caCertPool.AppendCertsFromPEM(caCert)

    // Create TLS configuration
    tlsConfig := &tls.Config{
        Certificates: []tls.Certificate{clientCert},
        RootCAs:      caCertPool,
        ServerName:   "otel-collector",
    }

    // Create gRPC connection with TLS
    conn, err := grpc.Dial("localhost:4317",
        grpc.WithTransportCredentials(credentials.NewTLS(tlsConfig)),
    )
    if err != nil {
        log.Fatalf("Failed to create gRPC connection: %v", err)
    }
    defer conn.Close()

    // Create OTLP trace exporter
    exporter, err := otlptracegrpc.New(
        context.Background(),
        otlptracegrpc.WithGRPCConn(conn),
    )
    if err != nil {
        log.Fatalf("Failed to create trace exporter: %v", err)
    }

    // Create trace provider
    tp := trace.NewTracerProvider(
        trace.WithBatcher(exporter),
        trace.WithResource(resource.NewWithAttributes(
            semconv.SchemaURL,
            semconv.ServiceNameKey.String("secure-test-app"),
            semconv.ServiceVersionKey.String("1.0.0"),
        )),
    )

    otel.SetTracerProvider(tp)

    // Create tracer
    tracer := otel.Tracer("secure-test-tracer")

    // Generate some test traces with sensitive data
    for i := 0; i < 10; i++ {
        ctx, span := tracer.Start(context.Background(), fmt.Sprintf("secure-operation-%d", i))
        
        span.SetAttributes(
            attribute.String("operation.type", "secure-transaction"),
            attribute.Int("transaction.id", i),
            attribute.String("sensitive_data", fmt.Sprintf("secret-value-%d", i)),
            attribute.String("user.id", fmt.Sprintf("user-%d", i)),
        )

        // Simulate some work
        time.Sleep(100 * time.Millisecond)
        
        span.End()
        ctx.Done()
    }

    // Shutdown trace provider
    if err := tp.Shutdown(context.Background()); err != nil {
        log.Printf("Error shutting down tracer provider: %v", err)
    }

    fmt.Println("Successfully sent encrypted telemetry data!")
}
