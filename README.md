# FAMILICAM

Hi, welcome to **FAMILICAM**, made by **Anna, Baptiste, Cyprien, Lia, and Theo** with love! ❤️

---

## Getting Started  

### Step 1: Clone and Prepare the Repository  
1. Access the **"MASTER" branch** on the GitHub page: [FAMILICAM GitHub Repository](https://github.com/CHAPTARD/FAMILICAM).  
2. Download the code in a `.zip` format.  
3. Extract the `.zip` into its own folder.  
4. Navigate to the root folder (the folder containing the `.git` and `lib` folders).  
5. Open this directory in **VS Code**.  

**Note:** Ensure you have the following prerequisites installed:  
- **Flutter Extension** in VS Code.  
- Firebase environment setup.  
- **JAVA** installed on your machine. If not, download and install it before proceeding.  

---

### Step 2: Adjust Configuration for Your Environment  
Due to the server's uncommon storage configuration, you need to modify a file:  

1. In VS Code, search for `gradle.properties`.  
2. Delete or comment out the following line:  
   ```properties
   org.gradle.java.home=F:/Java
   ```  
3. Save the changes (Ctrl+S).  

---

### Step 3: Setup Android Emulator  
1. Install **Android Studio** (if not already installed).  
2. In the bottom blue bar of VS Code, check the **JAVA status**:  
   - It should display **"JAVA: Ready"**.  
3. Select your emulator from the available devices (on the right after "Dart").  

**Note:** If no emulator is available, set up a virtual device in **Android Studio**.  

Alternatively, you can skip using the emulator and directly build the app by running:  
```bash
flutter build apk --release
```

---

### Step 4: Compile the App  
1. Open a terminal in VS Code (Ctrl+Shift+`).  
2. Run the following command:  
   ```bash
   flutter run
   ```  
**Note:** The first compilation might take a while (up to 15 minutes on slower devices). Be patient! Future compilations will be much faster.  

🎉 Congratulations! You have successfully compiled **FAMILICAM**!  

---

## Setting Up the Local File Server  

Since we can’t afford monthly online storage servers, we’ve set up a **local file server**. This allows the app to function within your local network.  

### Step 1: Install `files-upload-server`  
Install the required package using the following link: [files-upload-server on npm](https://www.npmjs.com/package/files-upload-server).  

### Step 2: Create the Directory Structure  
Create a directory with the following structure:  
```
/yourdir
    /upload
        /challenges
            /IDchallenge1
                apic.img
            /IDchallenge2
                avideo.vid
        /families
            /IDfamily1
                somepic.img
            /IDfamily2
                anotherpic.img
```

**Time-Saving Tip:** If you don’t want to create the directory manually, use our pre-made directory: [Download Pre-Made Directory](PUTLINKHERE).  

---

### Step 3: Start the Server  
1. Navigate to your directory in File Explorer (Win+E).  
2. In the top bar (showing the current location), double-click and type:  
   ```
   powershell
   ```  
   Press **Enter**.  

3. In the new PowerShell window, run the following command:  
   ```bash
   files-upload-server -d upload -p 8000
   ```  

---

## You're All Set! 🎉  
You’re now ready to:  
- Develop the app.  
- Use it on your local network.  

Enjoy **FAMILICAM**!
