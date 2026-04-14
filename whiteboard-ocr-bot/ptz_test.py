"""PTZ test helper for TAPO C200 via ONVIF.

Usage:
  ./venv/bin/python ptz_test.py status
  ./venv/bin/python ptz_test.py save-mom
  ./venv/bin/python ptz_test.py save-wb
  ./venv/bin/python ptz_test.py move <pan> <tilt>   # absolute, range -1..1
  ./venv/bin/python ptz_test.py goto-mom
  ./venv/bin/python ptz_test.py list

Note: TAPO C200 has NO zoom over ONVIF (AbsoluteZoomPositionSpace is empty).
Only pan/tilt are available.
"""
import time, sys
from onvif import ONVIFCamera
import config

cam = ONVIFCamera(config.TAPO_HOST, config.TAPO_ONVIF_PORT,
                  config.TAPO_RTSP_USER, config.TAPO_RTSP_PASS)
media = cam.create_media_service()
ptz = cam.create_ptz_service()
profile = media.GetProfiles()[0]
token = profile.token

def get_pos():
    s = ptz.GetStatus({"ProfileToken": token})
    return s.Position.PanTilt.x, s.Position.PanTilt.y

def move_abs(pan, tilt):
    req = ptz.create_type("AbsoluteMove")
    req.ProfileToken = token
    req.Position = {"PanTilt": {"x": pan, "y": tilt}}
    ptz.AbsoluteMove(req)

def save_preset(name):
    req = ptz.create_type("SetPreset")
    req.ProfileToken = token
    req.PresetName = name
    return ptz.SetPreset(req)

def goto_preset(name):
    presets = ptz.GetPresets({"ProfileToken": token})
    for p in presets:
        if p.Name == name:
            req = ptz.create_type("GotoPreset")
            req.ProfileToken = token
            req.PresetToken = p.token
            ptz.GotoPreset(req)
            return True
    return False

cmd = sys.argv[1] if len(sys.argv) > 1 else "status"

if cmd == "status":
    pan, tilt = get_pos()
    print(f"pan={pan:.4f} tilt={tilt:.4f}")

elif cmd == "save-mom":
    pan, tilt = get_pos()
    print(f"current: pan={pan:.4f} tilt={tilt:.4f}")
    token_id = save_preset(config.TAPO_PRESET_MONITOR)
    print(f"saved preset '{config.TAPO_PRESET_MONITOR}' → token={token_id}")

elif cmd == "save-wb":
    pan, tilt = get_pos()
    print(f"current: pan={pan:.4f} tilt={tilt:.4f}")
    token_id = save_preset(config.TAPO_PRESET_WHITEBOARD)
    print(f"saved preset '{config.TAPO_PRESET_WHITEBOARD}' → token={token_id}")

elif cmd == "move":
    target_pan = float(sys.argv[2])
    target_tilt = float(sys.argv[3])
    pan0, tilt0 = get_pos()
    print(f"from pan={pan0:.4f} tilt={tilt0:.4f}")
    print(f"to   pan={target_pan:.4f} tilt={target_tilt:.4f}")
    move_abs(target_pan, target_tilt)
    time.sleep(3)
    pan1, tilt1 = get_pos()
    print(f"arrived pan={pan1:.4f} tilt={tilt1:.4f}")

elif cmd == "goto-mom":
    if goto_preset(config.TAPO_PRESET_MONITOR):
        time.sleep(3)
        pan, tilt = get_pos()
        print(f"back to {config.TAPO_PRESET_MONITOR}: pan={pan:.4f} tilt={tilt:.4f}")
    else:
        print(f"preset '{config.TAPO_PRESET_MONITOR}' not found")

elif cmd == "goto-wb":
    if goto_preset(config.TAPO_PRESET_WHITEBOARD):
        time.sleep(3)
        pan, tilt = get_pos()
        print(f"at {config.TAPO_PRESET_WHITEBOARD}: pan={pan:.4f} tilt={tilt:.4f}")
    else:
        print(f"preset '{config.TAPO_PRESET_WHITEBOARD}' not found")

elif cmd == "list":
    presets = ptz.GetPresets({"ProfileToken": token})
    print(f"presets ({len(presets)}):")
    for p in presets:
        pos = p.PTZPosition
        pan = pos.PanTilt.x if pos and pos.PanTilt else "?"
        tilt = pos.PanTilt.y if pos and pos.PanTilt else "?"
        print(f"  {p.Name:15s} pan={pan} tilt={tilt} token={p.token}")
