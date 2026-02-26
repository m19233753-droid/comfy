#!/bin/bash
set -e

echo "=== Icekiub All-in-One Provisioning (After23 / m19233753-droid) ==="
echo "Запуск: $(date)"

# === CUSTOM NODES ===
cd /workspace/ComfyUI/custom_nodes || { echo "Папка custom_nodes не найдена!"; exit 1; }

echo "Установка/обновление custom nodes..."

declare -a nodes=(
  "ltdrdata/ComfyUI-Impact-Pack"
  "rgthree/rgthree-comfy"
  "ClownsharkBatwing/RES4LYF"
  "wallen0322/ComfyUI-WanAnimate-Enhancer"
  "kijai/ComfyUI-KJNodes"
  "Kosinkadink/ComfyUI-VideoHelperSuite"
  "Fannovel16/comfyui-frame-interpolation"
  "comfyanonymous/ComfyUI-Manager"          # обязательно для установки missing nodes
)

for repo in "${nodes[@]}"; do
  folder=$(basename "$repo")
  if [ -d "$folder" ]; then
    echo "Обновляем $repo..."
    cd "$folder" && git pull --ff-only || echo "Не удалось обновить $repo"
    cd ..
  else
    echo "Клонируем $repo..."
    git clone "https://github.com/$repo.git" || echo "Уже существует или ошибка: $repo"
  fi
done

# === MODELS & LORAS ===
cd /workspace/ComfyUI/models || { echo "Папка models не найдена!"; exit 1; }

mkdir -p unet vae loras clip clip_vision text_encoders frame_interpolation

echo "Скачивание моделей и LoRA (с -nc — не перезаписываем существующие)..."

# VAE
wget -nc -O vae/wan_2.1_vae.safetensors         "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"
wget -nc -O vae/flux2-vae.safetensors           "https://huggingface.co/Comfy-Org/flux2-klein-9B/resolve/main/split_files/vae/flux2-vae.safetensors"
wget -nc -O vae/ae.safetensors                  "https://huggingface.co/Comfy-Org/z_image/resolve/main/split_files/vae/ae.safetensors"

# CLIP Vision
wget -nc -O clip_vision/clip_vision_h.safetensors "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"

# Text Encoders
wget -nc -O text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
  "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
wget -nc -O text_encoders/qwen_3_8b_fp8mixed.safetensors \
  "https://huggingface.co/Comfy-Org/flux2-klein-9B/resolve/main/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors"
wget -nc -O text_encoders/qwen_3_4b.safetensors \
  "https://huggingface.co/Comfy-Org/z_image/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors"

# UNET / Diffusion Models
wget -nc -O unet/Wan2_2-Animate-14B_fp8_scaled_e4m3fn_KJ_v2.safetensors \
  "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_scaled_e4m3fn_KJ_v2.safetensors"
wget -nc -O unet/WAN2.2t2vLOWNOISEFP8.safetensors \
  "https://huggingface.co/icekiub/WAN-2.2-T2V-FP8-NON-SCALED/resolve/main/WAN2.2t2vLOWNOISEFP8.safetensors"
wget -nc -O unet/z_image_bf16.safetensors \
  "https://huggingface.co/Comfy-Org/z_image/resolve/main/split_files/unet/z_image_bf16.safetensors"
wget -nc -O unet/z_image_turbo_bf16.safetensors \
  "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/unet/z_image_turbo_bf16.safetensors"

# Klein (gated — требует HF_TOKEN и принятых условий на странице модели)
if [ -n "$HF_TOKEN" ]; then
  wget -nc --header="Authorization: Bearer $HF_TOKEN" -O unet/flux-2-klein-9b-fp8.safetensors \
    "https://huggingface.co/black-forest-labs/FLUX.2-klein-9b-fp8/resolve/main/flux-2-klein-9b-fp8.safetensors"
else
  echo "Внимание: HF_TOKEN не задан → Klein модель не скачается (gated)"
fi

# LoRAs
wget -nc -O loras/WanAnimate_relight_lora_fp16.safetensors \
  "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22_relight/WanAnimate_relight_lora_fp16.safetensors"
wget -nc -O loras/Wan21_I2V_14B_lightx2v_cfg_step_distill_lora_rank64.safetensors \
  "https://huggingface.co/lightx2v/Wan2.1-I2V-14B-480P-StepDistill-CfgDistill-Lightx2v/resolve/main/loras/Wan21_I2V_14B_lightx2v_cfg_step_distill_lora_rank64.safetensors"
wget -nc -O loras/Wan2.2-T2V-A14B-4steps-lora-250928_low_noise_model.safetensors \
  "https://huggingface.co/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-T2V-A14B-4steps-lora-250928/low_noise_model.safetensors"

# Z-Image related LoRAs (если они есть публично; если твои — добавь свои ссылки)
wget -nc -O loras/Z-Image-Fun-Lora-Distill-8-Steps-2602-ComfyUI.safetensors \
  "https://huggingface.co/alibaba-pai/Z-Image-Fun-Lora-Distill/resolve/main/Z-Image-Fun-Lora-Distill-8-Steps-2602-ComfyUI.safetensors"

# RIFE для Frame Interpolation (из WANT2V workflow)
wget -nc -O frame_interpolation/rife47.pth \
  "https://huggingface.co/comfyanonymous/ComfyUI_Frame_Interpolation_Models/resolve/main/rife47.pth"

echo "=== Provisioning завершён ==="
echo "Проверь логи. Если чего-то не хватает — в ComfyUI открой Manager → Install Missing Custom Nodes"
echo "Готово: $(date)"
