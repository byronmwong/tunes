require 'youtube_it'

module SongsHelper

  def song_from_soundcloud_url(url)
    client = SoundCloud.new(:client_id => ENV['SOUNDCLOUD_KEY'])
    begin
      sound_info = resolve_soundcloud_sound(client, url)
    rescue Exception => e
      raise 'Error resolving SoundCloud URL: ' + e.message
    end

    sound = Sound.find_by(sound_type: 'soundcloud', location: sound_info.id.to_s)

    return sound.song if sound

    artist_info = client.get("/users/#{sound_info.user_id}")

    song = Song.create({
      title: sound_info.title,
      artist: artist_info.username
    })

    sound = Sound.create({
      sound_type: 'soundcloud',
      location: sound_info.id.to_s,
      song: song
    })

    return song
  end

  def resolve_soundcloud_sound(client, url)
    sound_info = client.get('/resolve', :url => url)
    if !sound_info.streamable
      fail 'Sound is not streamable'
    end

    return sound_info
  end

  def song_from_youtube_url(url)
    client = YouTubeIt::Client.new(:dev_key => ENV['YOUTUBE_KEY'])
    begin
      video_info = client.video_by(url)
    rescue OpenURI::HTTPError => e
      if e.message == '404'
        raise 'Bad Youtube URL'
      elsif e.message == '403'
        raise 'Bad API Key'
      else
        # unexpected error
        raise e
      end
    end

    sound = Sound.find_by(sound_type: 'youtube', location: video_info.unique_id)

    return sound.song if sound

    song = Song.create({
      title: video_info.title,
      artist: video_info.author.name
    })

    sound = Sound.create({
      sound_type: 'youtube',
      location: video_info.unique_id,
      song: song
    })

    return song
  end
end
