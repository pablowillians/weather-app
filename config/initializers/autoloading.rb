module Services; end

Rails.autoloaders.main.push_dir(Rails.root.join("app/services"), namespace: Services)
