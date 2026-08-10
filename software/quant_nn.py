import torch
import torch.nn as nn
import torch.nn.functional as F


def train(model, dataloader, loss_fn, optimizer, device, epochs=20, print_output=False):
    model.train()

    for epoch in range(epochs):
        running_loss = 0.0

        for images, labels in dataloader:
            images, labels = images.to(device), labels.to(device)

            optimizer.zero_grad()
            pred = model(images)
            loss = loss_fn(pred, labels)
            loss.backward()
            optimizer.step()

            running_loss += loss.item()
        if print_output:
            print(f"Epoch {epoch+1}/{epochs} - Loss: {running_loss/len(dataloader):.4f}")
            print("." * 100)
    if not print_output:
        print(f"Loss: {running_loss/len(dataloader):.4f}")


def test(model, dataloader, device):
    model.eval()
    correct = 0
    size = len(dataloader.dataset)

    with torch.no_grad():
        for images, labels in dataloader:
            images, labels = images.to(device), labels.to(device)
            pred = model(images)
            correct += (pred.argmax(1) == labels).sum().item()
        print(f"Accuracy on test set: {correct / size:2%}")


def collect_activation_stats(model, dataloader, device="cpu"):
    model.eval()
    stats = {}

    def update(name, t):
        flat = t.detach().reshape(-1)
        n = flat.numel()
        s = stats.setdefault(name, {"min": float("inf"), "max": float("-inf"), "sum": 0.0, "sumsq": 0.0, "count": 0})
        s["min"] = min(s["min"], flat.min().item())
        s["max"] = max(s["max"], flat.max().item())
        s["sum"] += flat.sum().item()
        s["sumsq"] += (flat**2).sum().item()
        s["count"] += n

    with torch.no_grad():
        for x, _ in dataloader:
            x = x.to(device)
            model(x)  # populates model.debug for this batch
            for name, t in model.debug.items():
                update(name, t)

    summary = {}
    for name, s in stats.items():
        mean = s["sum"] / s["count"]
        var = max(s["sumsq"] / s["count"] - mean**2, 0.0)
        summary[name] = {"min": s["min"], "max": s["max"], "mean": mean, "std": var**0.5}
    return summary


class UnquantizedMLP(nn.Module):
    def __init__(self, intermediate_neruons):
        super().__init__()
        self.layer1 = nn.Linear(28 * 28, intermediate_neruons)
        self.layer2 = nn.Linear(intermediate_neruons, 10)

    def forward(self, x):
        x = torch.flatten(x, 1)

        l1 = self.layer1(x)
        r1 = F.relu(l1)

        l2 = self.layer2(r1)

        return l2


class QuantizedMLP(nn.Module):

    def __init__(self, intermediate_neruons, fake_quantizer, clip_out=False, quant_bias=False, out_quantizer=None):
        super().__init__()
        self.layer1 = nn.Linear(28 * 28, intermediate_neruons)
        self.layer2 = nn.Linear(intermediate_neruons, 10)
        self.fake_quantizer = fake_quantizer
        self.out_quantizer = out_quantizer or fake_quantizer
        self.clip_out = clip_out
        self.quant_bias = quant_bias
        self.debug = {}

    def forward(self, x):
        x = torch.flatten(x, 1)
        x_quant = self.fake_quantizer(x)

        w1_quant = self.fake_quantizer(self.layer1.weight)

        b1 = self.fake_quantizer(self.layer1.bias) if self.quant_bias else self.layer1.bias
        a1 = F.relu(F.linear(x_quant, w1_quant, b1))
        a1_quant = self.fake_quantizer(a1)

        w2_quant = self.fake_quantizer(self.layer2.weight)

        b2 = self.fake_quantizer(self.layer2.bias) if self.quant_bias else self.layer2.bias
        a2 = F.linear(a1_quant, w2_quant, b2)

        out = self.out_quantizer(a2) if self.clip_out else a2
        if not self.training:
            self.debug = {
                "x_quant": x_quant.detach(),
                "w1_quant": w1_quant.detach(),
                "b1": b1.detach(),
                "a1": a1.detach(),
                "a1_quant": a1_quant.detach(),
                "w2_quant": w2_quant.detach(),
                "b2": b2.detach(),
                "a2": a2.detach(),
                "out": out.detach(),
            }
        return out


class FakeQuantizationFunction(torch.autograd.Function):
    @staticmethod
    def forward(ctx, x, int_bits, frac_bits):
        total_bits = int_bits + frac_bits
        scale = 1.0 / (2**frac_bits)

        q_min = -(1 << (total_bits - 1))
        q_max = (1 << (total_bits - 1)) - 1

        x_scaled = torch.round(x / scale)

        in_range = (x_scaled >= q_min) & (x_scaled <= q_max)
        ctx.save_for_backward(in_range)

        x_clamped = torch.clamp(x_scaled, q_min, q_max)
        return x_clamped * scale

    @staticmethod
    def backward(ctx, grad_output):
        (in_range,) = ctx.saved_tensors
        grad_input = grad_output * in_range.to(grad_output.dtype)
        return grad_input, None, None


class FakeQuantizationLayer(nn.Module):
    def __init__(self, int_bits=1, frac_bits=7):
        super().__init__()
        self.int_bits = int_bits
        self.frac_bits = frac_bits
        self._quantize = FakeQuantizationFunction.apply

    def forward(self, x):
        return self._quantize(x, self.int_bits, self.frac_bits)


def main():
    print("test")


# # 
# import itertools, pandas as pd


# def build_model(cfg):
#     if not cfg["quantized"]:
#         return quant_nn.UnquantizedMLP(cfg["hidden"]).to(device)
#     q = quant_nn.FakeQuantizationLayer(cfg["int_bits"], cfg["frac_bits"])
#     out_q = quant_nn.FakeQuantizationLayer(cfg["out_int_bits"], cfg["out_frac_bits"]) if "out_int_bits" in cfg else None
#     return quant_nn.QuantizedMLP(
#         cfg["hidden"],
#         q,
#         clip_out=cfg.get("clip_out", False),
#         quant_bias=cfg.get("quant_bias", False),
#         out_quantizer=out_q,
#     ).to(device)


# def run_experiment(cfg, epochs=5, seed=0):
#     torch.manual_seed(seed)  # important — without this, small accuracy diffs (like your 97.3 vs 97.42) are just noise
#     model = build_model(cfg)
#     optimizer = optim.Adam(model.parameters(), lr=cfg.get("lr", 1e-3))
#     loss_fn = nn.CrossEntropyLoss()

#     history = []
#     model.train()
#     for _ in range(epochs):
#         running = 0.0
#         for images, labels in train_loader:
#             images, labels = images.to(device), labels.to(device)
#             optimizer.zero_grad()
#             loss = loss_fn(model(images), labels)
#             loss.backward()
#             optimizer.step()
#             running += loss.item()
#         history.append(running / len(train_loader))

#     model.eval()
#     correct = 0
#     with torch.no_grad():
#         for images, labels in test_loader:
#             images, labels = images.to(device), labels.to(device)
#             correct += (model(images).argmax(1) == labels).sum().item()

#     torch.save(model.state_dict(), f"checkpoints/{cfg['name']}.pt")  # keep the actual weights, not just the number
#     return {**cfg, "final_loss": history[-1], "accuracy": correct / len(test_loader.dataset)}


# configs = [
#     {"name": "unquantized", "quantized": False, "hidden": 128},
#     {"name": "q_b", "quantized": True, "hidden": 128, "int_bits": 1, "frac_bits": 7, "quant_bias": True},
#     {"name": "q_nb", "quantized": True, "hidden": 128, "int_bits": 1, "frac_bits": 7, "quant_bias": False},
#     {
#         "name": "q_bc",
#         "quantized": True,
#         "hidden": 128,
#         "int_bits": 1,
#         "frac_bits": 7,
#         "quant_bias": True,
#         "clip_out": True,
#     },
#     {
#         "name": "q_bc_wide",
#         "quantized": True,
#         "hidden": 128,
#         "int_bits": 1,
#         "frac_bits": 7,
#         "quant_bias": True,
#         "clip_out": True,
#         "out_int_bits": 4,
#         "out_frac_bits": 4,
#     },
# ]

# results = [run_experiment(cfg) for cfg in configs]
# df = pd.DataFrame(results).sort_values("accuracy", ascending=False)
# df.to_csv("experiment_results.csv", index=False)
# df


# ###
# grid = itertools.product([1, 2, 4], [4, 6, 7], [True, False])
# configs = [
#     {
#         "name": f"ib{ib}_fb{fb}_bias{qb}",
#         "quantized": True,
#         "hidden": 128,
#         "int_bits": ib,
#         "frac_bits": fb,
#         "quant_bias": qb,
#     }
#     for ib, fb, qb in grid
# ]
