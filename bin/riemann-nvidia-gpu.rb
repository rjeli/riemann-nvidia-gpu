#!/usr/bin/env ruby

# Gets stats for nvidia gpus (using nvidia-smi) and submits them to riemann.

require 'riemann/tools'

class Riemann::Tools::NvidiaGpuStats
  include Riemann::Tools

  def initialize
  end

  def report_metric(gpu_index, metric_name, metric_value)
    report(
           :service => "gpu.#{gpu_index}.#{metric_name}",
           :metric => metric_value,
           :state => :ok,
           :tags => ['riemann-nvidia-gpu', 'riemann'])
  end

  def tick
    begin
      nvidia_smi_output = `nvidia-smi --query-gpu=index,utilization.gpu,utilization.memory,memory.used,memory.total --format=csv`
    rescue
    end

    if not nvidia_smi_output.nil?
      nvidia_smi_output.split("\n").each do |gpu_line|
        gpu_line.match(/(\d+), (\d+) %, (\d+) %, (\d+) MiB, (\d+) MiB/) do |m|
          report_metric(m[1], "utilization.gpu", m[2].to_f / 100)
          report_metric(m[1], "utilization.memory", m[3].to_f / 100)
          report_metric(m[1], "memory.used_mb", m[4])
          report_metric(m[1], "memory.used", m[4].to_f / m[5].to_f)
        end
      end
    end
  end
end

Riemann::Tools::NvidiaGpuStats.run

