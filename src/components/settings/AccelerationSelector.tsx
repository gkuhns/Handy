import { type FC, useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { SettingContainer } from "../ui/SettingContainer";
import { Dropdown, type DropdownOption } from "../ui/Dropdown";
import { useSettings } from "../../hooks/useSettings";
import { commands } from "@/bindings";
import type { TranscribeAcceleratorSetting } from "@/bindings";

const ORT_LABELS: Record<string, string> = {
  auto: "Auto",
  cpu: "CPU",
  cuda: "CUDA",
  directml: "DirectML",
  rocm: "ROCm",
  openvino: "OpenVINO",
  open_vino: "OpenVINO",
  npu: "NPU",
};

function normalizeOrtValue(value: string): string {
  return value === "open_vino" ? "openvino" : value;
}

interface AccelerationSelectorProps {
  descriptionMode?: "tooltip" | "inline";
  grouped?: boolean;
}

function encodeTranscribeValue(
  accelerator: TranscribeAcceleratorSetting,
  gpuDevice: string | null,
): string {
  if (accelerator === "cpu") return "cpu";
  if (accelerator === "gpu" && gpuDevice !== null) return `gpu:${gpuDevice}`;
  return "auto";
}

function decodeTranscribeValue(value: string): {
  accelerator: TranscribeAcceleratorSetting;
  gpuDevice: string | null;
} {
  if (value === "cpu") return { accelerator: "cpu", gpuDevice: null };
  if (value.startsWith("gpu:")) {
    return { accelerator: "gpu", gpuDevice: value.slice(4) };
  }
  return { accelerator: "auto", gpuDevice: null };
}

export const AccelerationSelector: FC<AccelerationSelectorProps> = ({
  descriptionMode = "tooltip",
  grouped = false,
}) => {
  const { t } = useTranslation();
  const { getSetting, updateSetting, isUpdating } = useSettings();

  const [transcribeOptions, setTranscribeOptions] = useState<DropdownOption[]>(
    [],
  );
  const [ortOptions, setOrtOptions] = useState<DropdownOption[]>([]);

  useEffect(() => {
    commands.getAvailableAccelerators().then((available) => {
      const opts: DropdownOption[] = [];
      if (available.transcribe.includes("auto")) {
        opts.push({
          value: "auto",
          label: t("settings.advanced.acceleration.gpuDevice.auto"),
        });
      }

      if (available.transcribe.includes("gpu")) {
        for (const dev of available.gpu_devices) {
          const vramLabel =
            dev.total_vram_mb >= 1024
              ? `${(dev.total_vram_mb / 1024).toFixed(1)} GB`
              : `${dev.total_vram_mb} MB`;
          opts.push({
            value: `gpu:${dev.id}`,
            label: `${dev.name} (${vramLabel})`,
          });
        }
      }

      if (available.transcribe.includes("cpu")) {
        opts.push({ value: "cpu", label: "CPU" });
      }
      setTranscribeOptions(opts);

      const ortVals = available.ort.includes("auto")
        ? available.ort
        : ["auto", ...available.ort];
      setOrtOptions(
        ortVals.map((v) => {
          const normalized = normalizeOrtValue(v);
          return {
            value: normalized,
            label: ORT_LABELS[normalized] ?? v,
          };
        }),
      );
    });
  }, [t]);

  const currentAccelerator = getSetting("transcribe_accelerator") ?? "auto";
  const currentGpuDevice = getSetting("transcribe_gpu_device") ?? null;
  const currentTranscribe = encodeTranscribeValue(
    currentAccelerator as TranscribeAcceleratorSetting,
    currentGpuDevice as string | null,
  );
  const displayedTranscribe = transcribeOptions.some(
    (option) => option.value === currentTranscribe,
  )
    ? currentTranscribe
    : (transcribeOptions[0]?.value ?? null);
  const currentOrt = normalizeOrtValue(
    String(getSetting("ort_accelerator") ?? "auto"),
  );

  const handleTranscribeChange = async (value: string) => {
    const { accelerator, gpuDevice } = decodeTranscribeValue(value);
    await updateSetting("transcribe_gpu_device", gpuDevice);
    await updateSetting("transcribe_accelerator", accelerator);
  };

  return (
    <>
      <SettingContainer
        title={t("settings.advanced.acceleration.transcribe.title")}
        description={t("settings.advanced.acceleration.transcribe.description")}
        descriptionMode={descriptionMode}
        grouped={grouped}
        layout="horizontal"
      >
        <Dropdown
          options={transcribeOptions}
          selectedValue={displayedTranscribe}
          onSelect={handleTranscribeChange}
          disabled={
            isUpdating("transcribe_accelerator") ||
            isUpdating("transcribe_gpu_device")
          }
        />
      </SettingContainer>
      {ortOptions.length > 2 && (
        <SettingContainer
          title={t("settings.advanced.acceleration.ort.title")}
          description={t("settings.advanced.acceleration.ort.description")}
          descriptionMode={descriptionMode}
          grouped={grouped}
          layout="horizontal"
        >
          <Dropdown
            options={ortOptions}
            selectedValue={currentOrt}
            onSelect={(value) => updateSetting("ort_accelerator", value as never)}
            disabled={isUpdating("ort_accelerator")}
          />
        </SettingContainer>
      )}
    </>
  );
};
