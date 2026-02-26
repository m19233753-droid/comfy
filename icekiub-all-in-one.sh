#!/bin/bash
set -e

echo "🚀 Provisioning Icekiub workflows (Face Only, Full Body, ZIB+ZIT, WANT2V Faceswap)..."

cd /workspace/ComfyUI

# ====================== CUSTOM NODES ======================
echo "📦 Installing custom nodes..."
mkdir -p custom_nodes
cd custom_nodes

declare -a nodes=(
  "ltdrdata/ComfyUI-Impact-Pack"
  "rgthree/rgthree-comfy"
  "ClownsharkBatwing/RES4LYF"
  "wallen0322/ComfyUI-WanAnimate-Enhancer"
  "kijai/ComfyUI-KJNodes"
  "Kosinkadink/ComfyUI-VideoHelperSuite"
  "Fannovel16/comfyui-frame-interpolation"
  "comfyanonymous/ComfyUI-Manager"  # Добавь это
)

for repo in "${nodes[@]}"; do
  folder=$(basename "$repo")
  if [ ! -d "$folder" ]; then
    echo "Cloning $repo..."
    git clone --depth 1 "https://github.com/$repo.git" "$folder"
  else
    echo "$folder already exists"
  fi
done

cd ..

# ====================== MODELS ======================
echo "📥 Downloading models..."

mkdir -p models/unet models/vae models/clip_vision models/loras models/text_encoders models/clip

# Helper function (HF_TOKEN already in env)
download() {
  local url="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ $url == *huggingface.co* ]] && [ -n "$HF_TOKEN" ]; then
    echo "Downloading (with token): $dest"
    wget -q --show-progress -c --header="Authorization: Bearer $HF_TOKEN" -O "$dest" "$url"
  else
    echo "Downloading: $dest"
    wget -q --show-progress -c -O "$dest" "$url"
  fi
}

# === Common for all workflows ===
download "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" "models/clip_vision/clip_vision_h.safetensors"
download "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" "models/vae/wan_2.1_vae.safetensors"
download "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/WanAnimate_relight_lora_fp16.safetensors" "models/loras/WanAnimate_relight_lora_fp16.safetensors"
download "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_scaled_e4m3fn_KJ_v2.safetensors" "models/unet/Wan2_2-Animate-14B_fp8_scaled_e4m3fn_KJ_v2.safetensors"
download "https://huggingface.co/lightx2v/Wan2.1-I2V-14B-480P-StepDistill-CfgDistill-Lightx2v/resolve/main/loras/Wan21_I2V_14B_lightx2v_cfg_step_distill_lora_rank64.safetensors" "models/loras/Wan21_I2V_14B_lightx2v_cfg_step_distill_lora_rank64.safetensors"
download "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

# === Klein (ICY workflows) — gated, нужен доступ на HF ===
download "https://huggingface.co/black-forest-labs/FLUX.2-klein-9b-fp8/resolve/main/flux-2-klein-9b-fp8.safetensors" "models/unet/flux-2-klein-9b-fp8.safetensors"
download "https://huggingface.co/Comfy-Org/flux2-klein-9B/resolve/main/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors" "models/text_encoders/qwen_3_8b_fp8mixed.safetensors"
download "https://huggingface.co/Comfy-Org/flux2-klein-9B/resolve/main/split_files/vae/flux2-vae.safetensors" "models/vae/flux2-vae.safetensors"

# === WANT2V Faceswap ===
download "https://huggingface.co/icekiub/WAN-2.2-T2V-FP8-NON-SCALED/resolve/main/WAN2.2t2vLOWNOISEFP8.safetensors" "models/unet/WAN2.2t2vLOWNOISEFP8.safetensors"
download "https://huggingface.co/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-T2V-A14B-4steps-lora-250928/low_noise_model.safetensors" "models/loras/low_noise_model.safetensors"
download "https://huggingface.co/icekiub/WAN-2.2-T2V-FP8-NON-SCALED/resolve/main/WANTEST2_000000600_low_noise.safetensors" "models/loras/WANTEST2_000000600_low_noise.safetensors"

# Z-Image Base + Turbo
download "https://huggingface.co/Comfy-Org/z_image/resolve/main/split_files/unet/z_image_bf16.safetensors" "models/unet/z_image_bf16.safetensors"
download "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/unet/z_image_turbo_bf16.safetensors" "models/unet/z_image_turbo_bf16.safetensors"
download "https://huggingface.co/Comfy-Org/z_image/resolve/main/split_files/vae/ae.safetensors" "models/vae/ae.safetensors"  # Уже есть, но ок
download "https://huggingface.co/Comfy-Org/z_image/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors" "models/text_encoders/qwen_3_4b.safetensors"
download "https://huggingface.co/Comfy-Org/z_image/resolve/main/split_files/text_encoders/qwen_3_4b_fp8_mixed.safetensors" "models/text_encoders/qwen_3_4b_fp8_mixed.safetensors"  # Если нужно fp8

# LoRA из zbase
download "https://huggingface.co/alibaba-pai/Z-Image-Fun-Lora-Distill/resolve/main/Z-Image-Fun-Lora-Distill-8-Steps-2602-ComfyUI.safetensors" "models/loras/Z-Image-Fun-Lora-Distill-8-Steps-2602-ComfyUI.safetensors"
# Если LOURTA и nicegirls на HF — добавь их URLs здесь

echo "✅ Provisioning завершён! Все модели и ноды на месте."
echo "Теперь запускай инстанс — workflow’ы должны работать без ошибок missing models."
