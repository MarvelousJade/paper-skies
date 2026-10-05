# Audio

## Ring collection

The ring uses [SONIC RING SFX by PastaReaperYT](https://create.roblox.com/store/asset/111940732857414), a free Creator Store audio asset, ID `111940732857414`. Studio loaded its 0.952-second source. The client plays up to 450 ms and fades the final 60 ms, giving the bright ring attack a short audible tail. Playback speed stays at 1, with volume 0.20 (previously 0.35). A pickup-only EqualizerSoundEffect reduces HighGain to -8 dB and MidGain to -2 dB, with LowGain at 0 dB; wind and music are unaffected by this filter. This replaces the earlier dry UI Tick at the user's request; the pickup sample is a Creator Store asset, not original project music.

There is one `RingPickupChime` Sound instance. Rapid pickups restart it instead of stacking voices, and the duplicate-ring guard runs before playback. Sound OFF immediately stops the chime, mutes wind, and mutes music. Sound ON permits new chimes and restores music volume without restarting the song.

## Paper Skies — original chill electronic loop

- File: `assets/audio/PaperSkies.wav`
- 100 BPM, 32 bars, 76.8 seconds; stereo 44.1 kHz, 16-bit PCM WAV.
- Warm extended chords, rounded bass, soft four-on-the-floor drums, light plucked synths, and a quieter middle section. No vocals or hard drops.
- Original algorithmic composition and synthesized instruments created for this project. No external recordings or samples, and no claim that a connected music-generation model produced it.
- Generator: `tools/GenerateChillMusic.py`; requires Python with numpy and scipy. Run `python tools/GenerateChillMusic.py` to regenerate.
- Circular instrument releases and delay tails preserve the musical loop. A 3 ms waveform boundary correction prevents a discontinuity.
- Render report: `assets/audio/PaperSkies.json`. File size 13,547,564 bytes; peak -2.05 dBFS; RMS -15.62 dBFS; zero clipped samples; zero PCM jump at the loop boundary.

These measurements check file integrity, not whether the music suits the player. Studio playback and end-to-start looping are verified below; subjective listening review remains pending.

## Enable the original track in Roblox

The user uploaded the WAV as **PaperSkies**, asset `126932983544303`, owned by `robyu6767`. `Config.MusicSoundId` now points to this asset. Studio successfully loaded it with a duration of 76.8 seconds. The original WAV remains in the repository.

For future replacement tracks:

1. Import `assets/audio/PaperSkies.wav` through Studio's Asset Manager or Creator Dashboard under the intended owner. Follow [Roblox audio asset import instructions](https://create.roblox.com/docs/audio/assets).
2. After moderation, grant this experience permission to use the audio if required and copy its asset ID.
3. Set `Config.MusicSoundId = "rbxassetid://YOUR_AUDIO_ID"` in `src/shared/Config.luau`. `Config.MusicVolume` defaults to 0.16 so ring and wind feedback can remain audible.
4. Regenerate the installer with `python tools/GenerateExplorationInstaller.py`, sync the updated Config into Studio, and start a fresh Play session.
5. Listen through a full loop, verify Sound OFF/ON, then verify playback and permissions in the published experience.

The client already creates a local, non-positional loop when a music ID is configured. It starts once per client session, rather than restarting on every throw. Music is configured to play continuously at volume 0.16, including between throws.

## Earlier Studio checks

- Previous UI Tick revision: one ring voice, fixed pitch, and successful asset load.
- Two notifications with the same ring ID produced one click.
- Two different IDs 70 ms apart each triggered the single voice; the tail stopped.
- Sound OFF suppressed the next pickup and muted wind; Sound ON restored pickup playback.
- Before upload, an empty music ID created no music Sound and requested no placeholder asset.
- After upload, a fresh Play session automatically created PaperSkiesMusic with asset `126932983544303`, loaded duration 76.8 seconds, looping enabled, and volume 0.16.
- Seeking to 0.5 seconds before the end and waiting 1.2 seconds produced a DidLoop event with playback continuing near the beginning. This tests the wrap without claiming a full uninterrupted listening pass.
- The actual Sound button muted music to zero while its position kept advancing; toggling ON restored volume 0.16 without restarting.

The smoke checks injected synthetic client feedback IDs only; they did not award gold or modify server collection state. Full flown collection, subjective sound review, and published-experience permissions remain manual checks.


Current chime Play check: asset loaded at 0.952 seconds; one pickup plus its duplicate and two rapid unique pickups produced exactly three sound starts. The tail stopped, Sound OFF suppressed the next pickup, and the toggle was restored to ON. These synthetic feedback IDs did not award server gold. The fresh client also loaded all seventy high-sky rings and 336 total rewards. Subjective listening approval and published audio permissions remain pending.

Softer pickup Play check: source loaded; volume 0.20; enabled pickup-only EQ at -8 dB high, -2 dB mid, 0 dB low. One pickup plus duplicate and two rapid pickups yielded three starts, with maximum volume 0.20 and the tail stopped. Music continued playing and neither wind nor music had the pickup EQ. Temporary audio-test connections were disconnected. Listening feedback remains pending.
