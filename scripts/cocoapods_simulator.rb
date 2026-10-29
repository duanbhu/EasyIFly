# Call from the host Podfile's post_integrate hook. Keep the original SDK for devices,
# but exclude its copy and link steps from every simulator architecture.
def easyifly_enable_simulator(installer)
  installer.pods_project.targets.each do |target|
    next unless target.name == 'EasyIFly'

    target.shell_script_build_phases.each do |phase|
      next unless phase.name == '[CP] Copy XCFrameworks'
      phase.shell_script = <<~SH + phase.shell_script
        # EasyIFly: simulator uses the Swift preview implementation.
        if [ "$PLATFORM_NAME" = "iphonesimulator" ]; then
          exit 0
        fi
      SH
      # The generated output paths refer to a framework intentionally absent on
      # simulator. Let the phase run so its platform guard can decide.
      phase.input_paths = []
      phase.output_paths = []
      phase.input_file_list_paths = []
      phase.output_file_list_paths = []
      phase.always_out_of_date = '1'
    end
  end

  installer.aggregate_targets.each do |target|
    next unless target.pod_targets.any? { |pod| pod.pod_name == 'EasyIFly' }

    target.xcconfigs.each do |configuration, config|
      flags = config.to_hash['OTHER_LDFLAGS']
      next unless flags

      # Keep all other dependencies and preserve the device linker flags.
      config.attributes['OTHER_LDFLAGS[sdk=iphonesimulator*]'] =
        flags.gsub('$(inherited)', '').gsub('${inherited}', '').gsub(/-framework\s+"?iflyMSC"?(?=\s|$)/, '').strip
      paths = config.attributes['FRAMEWORK_SEARCH_PATHS']
      if paths
        config.attributes['FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*]'] =
          paths.gsub('$(inherited)', '').gsub('${inherited}', '').gsub(/\s*"\$\{PODS_XCFRAMEWORKS_BUILD_DIR\}\/EasyIFly"/, '')
      end
      config.save_as(target.xcconfig_path(configuration))
    end
  end
  installer.pods_project.save
end
