import QtQuick
import QtMultimedia
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support

WallpaperItem {
    id: wp
    property bool onBattery: false
    readonly property bool wantVideo: wp.configuration.Animate && !(wp.configuration.PauseOnBattery && onBattery)

    P5Support.DataSource {          // pause video when running on battery
        engine: "powermanagement"
        connectedSources: ["AC Adapter"]
        onDataChanged: {
            const ac = data["AC Adapter"];
            wp.onBattery = ac !== undefined && ac["Plugged in"] === false;
        }
    }

    Image {                       // static fallback, always present underneath
        anchors.fill: parent
        source: wp.configuration.StillUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
    MediaPlayer {
        id: player
        source: wp.configuration.VideoUrl
        loops: MediaPlayer.Infinite
        videoOutput: out
        audioOutput: null          // video wallpaper is always silent
    }
    VideoOutput {
        id: out
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        visible: player.playbackState === MediaPlayer.PlayingState
    }
    onWantVideoChanged: wantVideo ? player.play() : player.pause()
    Component.onCompleted: if (wantVideo) player.play()
}
