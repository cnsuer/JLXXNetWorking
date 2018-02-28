module Fastlane
  module Actions
    module SharedValues
      GIT_REMOVE_TAG_CUSTOM_VALUE = :GIT_REMOVE_TAG_CUSTOM_VALUE
    end

    class GitRemoveTagAction < Action
      def self.run(params)

        tagVersion = params[:tag]
        isRemoveLocal = params[:rL]
        isRemoveRemote = params[:rR]
        
        #1.定义一个数组,存储所有需要执行的命令
        cmds = []
        #2.向数组中,添加命令
        #删除本地tag
        #git tag -d tag
        if isRemoveLocal
        cmds << "git tag -d #{tagVersion} "
        end
        #删除远程tag
        #git push origin :tag
        if isRemoveRemote
        cmds << " git push origin :#{tagVersion}"
        end
        #3.执行命令
        result = Actions.sh(cmds.join('&'))
      return result
     end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "删除tag"
      end

      def self.details
        # Optional:
        # this is your chance to provide a more detailed description of this action
        "使用这个action,来删除本地或者远程tag"
      end

      def self.available_options
        # Define all options your action supports. 
        
        # Below a few examples
        [
            FastlaneCore::ConfigItem.new(key: :tag,
                             description: "本地或者远程库,需要被删除的tag",
                             is_string: true,
                             optional:false),

            FastlaneCore::ConfigItem.new(key: :rL,
                             description: "是否需要删除本地的tag",
                             is_string: false, # true: verifies the input is a string, false: every kind of value
                             default_value: true,
                             optional:true),
                                        
            FastlaneCore::ConfigItem.new(key: :rR,
                             description: "是否需要删除远程的tag",
                             is_string: false, # true: verifies the input is a string, false: every kind of value
                             default_value: true)
        ]
      end

      def self.output

      end

      def self.return_value
        nil
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["cnsuer"]
      end

      def self.is_supported?(platform)
        # you can do things like
        # 
        #  true
        # 
        #  platform == :ios
        # 
        #  [:ios, :mac].include?(platform)
        # 

        platform == :ios
      end
    end
  end
end
