#encoding: utf-8

module GameData
  # Merge system that help PSDK to update itself to a newer version
  module Merge
    # List of File to consider to create a project merge
    FileList = []
    FileList << "Text/de.dat" << "Text/en.dat" << "Text/es.dat" <<
      "Text/fr.dat" << "Text/it.dat" << "Text/kana.dat" << "Text/ko.dat" <<
      "PSDK/Abilities.rxdata" << "PSDK/ItemData.rxdata" <<
      "PSDK/MapData.rxdata" << "PSDK/Maplinks.rxdata" <<
      "PSDK/Natures.rxdata" << "PSDK/PokemonData.rxdata" <<
      "PSDK/Quests.rxdata" << "PSDK/SkillData.rxdata" <<
      "PSDK/SystemTags.rxdata" << "PSDK/Trainers.rxdata" <<
      "PSDK/Types.rxdata" << "CommonEvents.rxdata" <<
      "System.rxdata" << "Tilesets.rxdata" << "Troops.rxdata"

      
    # List of file that are compressed
    DeflatedFiles = []
    DeflatedFiles << "Text/de.dat" << "Text/en.dat" << "Text/es.dat" <<
      "Text/fr.dat" << "Text/it.dat" << "Text/kana.dat" << "Text/ko.dat"
    # Path of the data
    Data_Path = "Data/"
    # New PSDK version file
    NewPSDK = Data_Path + "NewPSDK"
    # Old PSDK version file
    OldPSDK = Data_Path + "OldPSDK"

    module_function
    # This function will generate a file that contain the old PSDK files
    # @param output_filename [String] the file where the whole data will be stored
    # @return [Hash<String => Object>] all the file loaded (filename => data)
    def create_old_psdk_version(output_filename = OldPSDK)
      old_data = {}
      # Loading each files
      FileList.each do |filename|
        data = load_data(Data_Path + filename) rescue nil
        next unless data
        # If the file is deflated we inflate it and loads its contents
        if DeflatedFiles.include?(filename)
          data = Marshal.load(Zlib::Inflate.inflate(data))
        end
        old_data[filename] = data
      end
      # Saving the old data
      save_data(Zlib::Deflate.deflate(Marshal.dump(old_data)), output_filename)
      return old_data
    end

    # This function will generate a file that contain the new PSDK files
    # @return [Hash<String => Object>] all the file loaded (filename => data)
    def create_new_psdk_version
      create_old_psdk_version(NewPSDK)
    end

    # Check if there's an update and applies the update to the project
    def check_and_update
      # If no update don't update
      unless File.exist?(NewPSDK)
        puts "No PSDK update detected..."
        return
      end
      unless File.exist?(OldPSDK)
        puts "#{OldPSDK} not found, no possible update."
        return
      end
      puts "PSDK update detected..."
      backup_filename = Data_Path + Time.new.strftime("%Y.%j%H%M%S.bak")
      puts "Making backup file : #{backup_filename}..."
      project_data = create_old_psdk_version(backup_filename)
      diff_data = make_diff(project_data)
      if File.expand_path(".") == "E:\nuriy\Work\PSDK-Alpha-20"
        puts "No update allowed here."
        puts Marshal.dump(diff_data).bytesize
        return
      end
      merge(diff_data)
      clean
      puts "Project updated!"
      GC.start
    end

    # Generate the differential of the project data to the old PSDK version
    # @param project_data [Hash<String => Object>] the project data
    # @return [Hash<String => Object>] the differential data
    def make_diff(project_data)
      old_data = load_archive(OldPSDK)
      diff_data = {}
      old_data.each do |filename, data|
        new_data = project_data[filename]
        next unless new_data # If the project data does not exist
        if(data.class == ::Array)
          diff_data[filename] = ArrayDiffData.new(data, new_data)
        else
          diff_data[filename] = DiffData.new(data, new_data)
        end
      end
      return diff_data
    end

    # Load a PSDK archive (old or new)
    # @param filename [String] the name of the PSDK archive
    # @return [Hash<String => Object>] the archive data
    def load_archive(filename)
      Marshal.load(Zlib::Inflate.inflate(load_data(filename)))
    end

    # Merge the differential data to the new PSDK data
    # @param diff_data [Hash<String => Object>] the differential data
    def merge(diff_data)
      new_data = load_archive(NewPSDK)
      new_data.each do |filename, data|
        diff = diff_data[filename]
        if diff
          data = diff.apply(data)
        end
        # If the file should normaly be deflated
        if DeflatedFiles.include?(filename)
          data = Zlib::Deflate.deflate(Marshal.dump(data))
        end
        save_data(data, Data_Path + filename)
      end
    end
    # Clean the data path (remove the newPSDK file)
    def clean
      File.delete(OldPSDK)
      File.rename(NewPSDK, OldPSDK)
    end
  end
  # Automatically check the new update
  Merge.check_and_update
end
