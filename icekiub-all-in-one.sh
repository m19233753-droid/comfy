#!/bin/bash
set -e

echo "=== Icekiub All-in-One Provisioning (Nastya / m19233753-droid) ==="
echo "Объединённый скрипт: Face Only, Full Body Klein Swap, Zbase+ZIT, WANT2V Faceswap"
echo "Запуск: $(date)"

# ====================== CUSTOM NODES ======================
cd /workspace/ComfyUI/custom_nodes || { echo "Ошибка: папка custom_nodes не найдена!"; exit 1; }

echo "Установка/обновление custom nodes..."

declare -a nodes=(
  "ltdrdata/ComfyUI-Impact-Pack"
  "rgthree/rgthree-comfy"                  # правильный репозиторий rgthree
  "ClownsharkBatwing/RES4LYF"              # оригинальный для ClownsharKSampler
  "wallen0322/ComfyUI-WanAnimate-Enhancer"
  "kijai/ComfyUI-KJNodes"                  # правильный kijai
  "Kosinkadink/ComfyUI-VideoHelperSuite"
  "Fannovel16/comfyui-frame-interpolation"
  "comfyanonymous/ComfyUI-Manager"         # для установки missing nodes
)

for repo in "${nodes[@]}"; do
  folder=$(basename "$repo")
  if [ -d "$folder" ]; then
    echo "Обновляем $repo..."
    cd "$folder" && git pull --ff-only || echo "Не удалось обновить $repo"
    cd ..
  else
    echo "Клонируем $repo..."
    git clone --depth 1 "https://github.com/$repo.git" || echo "Уже существует или ошибка: $repo"
  fi
done

# ====================== MODELS & LORAS ======================
cd /workspace/ComfyUI/models || { echo "Ошибка: папка models не найдена!"; exit 1; }

mkdir -p unet vae loras clip clip_vision text_encoders frame_interpolation

echo "Скачивание моделей и LoRA (с -nc/-c — не перезагружаем существующие)..."

# Helper для скачивания (поддержка HF_TOKEN для gated)
download() {
  local url="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  echo "Скачиваю → $dest"
  if [[ $url == *huggingface.co* && -n "$HF_TOKEN" ]]; then
    wget -q --show-progress -nc -c --header="Authorization: Bearer $HF_TOKEN" -O "$dest" "$url" || echo "Ошибка скачивания (возможно gated): $url"
  else
    wget -q --show-progress -nc -c -O "$dest" "$url" || echo "Ошибка скачивания: $url"
  fi
}

# === Общие для всех ===
download "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" "clip_vision/clip_vision_h.safetensors"
download "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" "vae/wan_2.1_vae.safetensors"
download "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

# === Wan Animate (ICY + WANT2V) ===
download "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_scaled_e4m3fn_KJ_v2.safetensors" "unet/Wan2_2-Animate-14B_fp8_scaled_e4m3fn_KJ_v2.safetensors"
download "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22_relight/WanAnimate_relight_lora_fp16.safetensors" "loras/WanAnimate_relight_lora_fp16.safetensors"
download "https://huggingface.co/lightx2v/Wan2.1-I2V-14B-480P-StepDistill-CfgDistill-Lightx2v/resolve/main/loras/Wan21_I2V_14B_lightx2v_cfg_step_distill_lora_rank64.safetensors" "loras/Wan21_I2V_14B_lightx2v_cfg_step_distill_lora_rank64.safetensors"

# === Klein (ICY Face/Full Body) ===
if [ -n "$HF_TOKEN" ]; then
  download "https://huggingface.co/black-forest-labs/FLUX.2-klein-9b-fp8/resolve/main/flux-2-klein-9b-fp8.safetensors" "unet/flux-2-klein-9b-fp8.safetensors"
  download "https://huggingface.co/Comfy-Org/flux2-klein-9B/resolve/main/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors" "text_encoders/qwen_3_8b_fp8mixed.safetensors"
  download "https://huggingface.co/Comfy-Org/flux2-klein-9B/resolve/main/split_files/vae/flux2-vae.safetensors" "vae/flux2-vae.safetensors"
else
  echo "ВНИМАНИЕ: HF_TOKEN не задан → модели Klein не скачаются (gated модель)"
fi

# === WANT2V Faceswap ===
download "https://huggingface.co/icekiub/WAN-2.2-T2V-FP8-NON-SCALED/resolve/main/WAN2.2t2vLOWNOISEFP8.safetensors" "unet/WAN2.2t2vLOWNOISEFP8.safetensors"
download "https://huggingface.co/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-T2V-A14B-4steps-lora-250928/low_noise_model.safetensors" "loras/Wan2.2-T2V-A14B-4steps-low_noise_model.safetensors"

# === Zbase + ZIT ===
download "https://huggingface.co/Comfy-Org/z_image/resolve/main/split_files/unet/z_image_bf16.safetensors" "unet/z_image_bf16.safetensors"
download "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/unet/z_image_turbo_bf16.safetensors" "unet/z_image_turbo_bf16.safetensors"
download "https://huggingface.co/Comfy-Org/z_image/resolve/main/split_files/vae/ae.safetensors" "vae/ae.safetensors"
download "https://huggingface.co/Comfy-Org/z_image/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors" "text_encoders/qwen_3_4b.safetensors"

# === RIFE для интерполяции (WANT2V) ===
download "https://huggingface.co/comfyanonymous/ComfyUI_Frame_Interpolation_Models/resolve/main/rife47.pth" "frame_interpolation/rife47.pth"

echo "=== Provisioning завершён успешно! ==="
echo "Все основные модели и ноды скачаны/установлены."
echo "Если в ComfyUI будут missing nodes — используй Manager → Install Missing Custom Nodes → Restart"
echo "Готово: $(date)"
