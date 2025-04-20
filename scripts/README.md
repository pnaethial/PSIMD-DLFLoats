## 🔗 External Dependency: Floating Point Execution Unit

This project integrates a Floating Point Execution Unit from an external repository to support IEEE-compliant 16-bit operations and optimize DLFloat computations.

The core floating-point logic is reused and adapted from:

➡️ [Floating-Point Unit Repository](https://github.com/ananya343B/DL_FPU/tree/main)

This module is responsible for:
- Executing arithmetic operations (add, mul, div, sqrt, comparator, float to int , int to float, mac, sub) on 16-bit DLFloat operands
- Handling floating-point exceptions: overflow, underflow, inexact, division-by-zero, invalid
- Conforming to IEEE-754 standards for packed SIMD deep learning operations

![image](https://github.com/user-attachments/assets/7f2721ad-c58b-41fd-8f1c-8b2598480d1a)

![image](https://github.com/user-attachments/assets/a2539509-6ddc-46c9-a9df-a1a9be5df4c4)

<section id="model-workflow">
  <h2>Model Workflow & Performance Comparison</h2>

  <h3>1. Model Parameter Initialization</h3>
  <p>
    Proper initialization of weights and biases is critical to ensure stable training and inference.  
    We typically use <strong>Xavier (Glorot) initialization</strong> for fully‑connected layers:
  </p>
  <ul>
    <li>
      <code>weight</code> values are drawn from a uniform distribution  
      \(\displaystyle U\bigl(-\frac{\sqrt{6}}{\sqrt{n_{\text{in}}+n_{\text{out}}}},\ \frac{\sqrt{6}}{\sqrt{n_{\text{in}}+n_{\text{out}}}}\bigr)\)  
      where \(n_{\text{in}}\) and \(n_{\text{out}}\) are the fan‑in and fan‑out dimensions.
    </li>
    <li>
      <code>bias</code> values are typically initialized to zero to avoid introducing unintended offsets.
    </li>
  </ul>

  <h3>2. Type Conversion to DLFloat16 &amp; IEEE FP16</h3>
  <p>
    Once initialized, all <code>float32</code> tensors—both model parameters and inputs—are converted into 16-bit formats:
  </p>
  <ul>
    <li>
      <strong>IEEE‑754 FP16:</strong> Standard half‑precision format with 1 sign bit, 5 exponent bits (bias 15), and 10 mantissa bits.
    </li>
    <li>
      <strong>DLFloat16:</strong> Custom 16‑bit format with 1 sign bit, 6 exponent bits (bias 31), and 9 mantissa bits, optimized to avoid denormals and simplify hardware.
    </li>
  </ul>
  <p>
    This conversion reduces memory bandwidth and storage requirements, and allows us to measure performance trade‑offs between the two formats.
  </p>

  <h3>3. Forward Pass &amp; Activation</h3>
  <p>
    During inference, each input batch is fed through the network in a single forward pass:
  </p>
  <ol>
    <li><strong>Linear layer:</strong> Compute <code>Y = X·Wᵀ + b</code> via matrix–vector multiplication.</li>
    <li><strong>ReLU activation:</strong> Apply <code>ReLU(z) = max(0, z)</code> element‑wise to introduce non‑linearity.</li>
    <li>All operations are performed in the selected 16‑bit format (DLFloat16 or FP16).</li>
  </ol>

  <h3>4. Latency Measurement &amp; Comparison</h3>
  <p>
    To evaluate performance, we measure the wall‑clock time for <strong>N</strong> repeated inferences and compute the average latency:
  </p>
  <pre><code>// Pseudocode
start = now()
for i in 1..N:
    out = model.forward(input)
end
latency_ms = (now() - start) / N * 1000
</code></pre>
  <p>
    By comparing the average latency for DLFloat16 vs IEEE‑FP16, we can quantify the benefits of the custom format:
  </p>
  <ul>
    <li><strong>Throughput:</strong> Inferences per second</li>
    <li><strong>Latency:</strong> Milliseconds per inference</li>
    <li><strong>Accuracy:</strong> Numerical fidelity of outputs</li>
  </ul>

  <p>
    This workflow demonstrates how a lightweight 16‑bit coprocessor can accelerate deep learning inference with minimal precision loss and lower hardware complexity.
  </p>
</section>
