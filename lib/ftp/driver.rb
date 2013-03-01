# coding: utf-8

require File.expand_path('../../../config/environment.rb',  __FILE__)
require File.expand_path('../file_operations', __FILE__)

# a super simple FTP server with hard coded auth details and only two files
# available for download.
module Ftp
  class Driver
    FILE_ONE = "This is the first file available for download.\n\nBy James"
    FILE_TWO = "This is the file number two.\n\n2009-03-21"

    def change_dir(path, &block)
      yield path == "/" || path == "/files"
    end

    def dir_contents(path, &block)
      yield []
    end

    def authenticate(user, pass, &block)
      val = case user
        when 'anonymous'
          @user = 'anonymous'
          true
        else
          @user = User.where(email: user).first
          @user && @user.valid_password?(pass) && @user.directory
        end
      Rails.logger.info "#{val ? 'Successful' : 'Unsuccessful'} FTP sign in attempt for: #{user}"
      yield val
    end

    def bytes(path, &block)
      yield case path
            when "/one.txt"       then FILE_ONE.size
            when "/files/two.txt" then FILE_TWO.size
            else
              false
            end
    end

    def get_file(*args, &block)
      yield ftp_methods(:get_file, args)
    end

    def put_file(*args, &block)
      yield ftp_methods(:put_file, args)
    end

    def delete_file(path, &block)
      yield false
    end

    def delete_dir(path, &block)
      yield false
    end

    def rename(from, to, &block)
      yield false
    end

    def make_dir(path, &block)
      yield false
    end

    private

    def dir_item(name)
      EM::FTPD::DirectoryItem.new(:name => name, :directory => true, :size => 0)
    end

    def file_item(name, bytes)
      EM::FTPD::DirectoryItem.new(:name => name, :directory => false, :size => bytes)
    end

    private
      def ftp_methods( method, args )
        case method
        when :put_file
          return false if @user == 'anonymous'
        when :get_file
          return false if @user != 'anonymous'
        end

        # We have to map each ftp path to a local file system path to check 
        # permissions, but when command is 'put_file' the second argument
        # is an absolute path to temporary that should not be converted
        if method == :put_file
          tmp_file = args.delete_at( 1 )
          args = args.map{ |arg| file_system_path( @user.directory, arg ) }
        else
          args = args.map{ |arg| file_system_path( Bawstun::Application.config.ftp_download_base, arg ) }
        end



        begin
          # Bypass permissions for second argument if method is put_file
          #args.each{ |arg| check_file_system_permissions!( arg ) }
          args.insert( 1, tmp_file ) if method == :put_file

          value = Ftp::FileOperations.send( method, *args )

          return value
        rescue Exception => e
          Rails.logger.error "FTP: #{e.message} when #{@user} trying to #{method}"
          return false
        end
      end

      def file_system_path( base_path, ftp_path )
        File.join base_path, ftp_path
      end
  end
end

# configure the server
#driver     Ftp::Driver
#driver_args 1, 2, 3
#user      "ftp"
#group     "ftp"
#daemonise false
#name      "fakeftp"
#pid_file  "/var/run/fakeftp.pid"