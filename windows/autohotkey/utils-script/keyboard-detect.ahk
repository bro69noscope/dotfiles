CurrentKeyboard := ""

DetectAndSetKeyboard() {
  global CurrentKeyboard
  detectedNames := DetectSpecificKeyboard()

  for keyboard in detectedNames
    MsgBox("Detected: " . keyboard)

  for keyboard in detectedNames {
    if (keyboard = "Keychron Q3") {
      CurrentKeyboard := "keychronQ3"
      break
    }
    else if (keyboard = "Glove80") {
      CurrentKeyboard := "glove"
      break
    }
  }

  WriteKeyboardInfoFile()
}

DetectSpecificKeyboard() {
  keyboards := GetKeyboardInfo()
  detectedKeyboards := []
  for keyboard in keyboards {
    keyboardType := "Unknown"
    ; Check VID/PID in Device ID
    if InStr(keyboard.DeviceID, "VID_3434&PID_0121") {
      keyboardType := "Keychron Q3"
    }
    else if InStr(keyboard.DeviceID, "VID_16C0&PID_27DB") {
      keyboardType := "Glove80"
    }
    ; Only add unique keyboards (avoid duplicates from multiple interfaces)
    found := false
    for existing in detectedKeyboards {
      if (existing = keyboardType) {
        found := true
        break
      }
    }
    if (!found && keyboardType != "Unknown") {
      detectedKeyboards.Push(keyboardType)
    }
  }
  return detectedKeyboards
}

; Get keyboard information via WMI
GetKeyboardInfo() {
  keyboards := []
  for objItem in ComObjGet("winmgmts:").ExecQuery("SELECT * FROM Win32_Keyboard") {
    keyboards.Push({
      Name: objItem.Name,
      Description: objItem.Description,
      DeviceID: objItem.DeviceID,
      PNPDeviceID: objItem.PNPDeviceID
    })
  }
  return keyboards
}

WriteKeyboardInfoFile() {
  keyboards := GetKeyboardInfo()
  outputFile := "keyboard_info.txt"
  if FileExist(outputFile) {
    FileDelete(outputFile)
  }

  for keyboard in keyboards {
    content := "Name: " . keyboard.Name . "`n"
      . "Description: " . keyboard.Description . "`n"
      . "Device ID: " . keyboard.DeviceID . "`n"
      . "PNP Device ID: " . keyboard.PNPDeviceID . "`n"
      . "----------------------------------------`n"
    FileAppend(content, outputFile)
  }
}
