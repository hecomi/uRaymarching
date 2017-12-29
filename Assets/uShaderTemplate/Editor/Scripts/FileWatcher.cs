using System.IO;
using UnityEngine.Events;

namespace uShaderTemplate
{

public class FileWatcher
{
    FileSystemWatcher watcher_;
    bool hasChanged_ = false;
    FileSystemEventHandler onChangedHandler_;
    RenamedEventHandler onRenamedHandler_;

    public UnityEvent onChanged = new UnityEvent();

    public void Start(string path)
    {
        watcher_ = new System.IO.FileSystemWatcher();
        watcher_.Path = Path.GetDirectoryName(path);
        watcher_.NotifyFilter = 
            NotifyFilters.LastAccess | 
            NotifyFilters.LastWrite |
            NotifyFilters.FileName | 
            NotifyFilters.DirectoryName;
        watcher_.Filter = Path.GetFileName(path);

        onChangedHandler_ = new FileSystemEventHandler(OnChanged);
        onRenamedHandler_ = new RenamedEventHandler(OnRenamed);
        watcher_.Changed += onChangedHandler_;
        watcher_.Created += onChangedHandler_;
        watcher_.Deleted += onChangedHandler_;
        watcher_.Renamed += onRenamedHandler_;

        watcher_.EnableRaisingEvents = true;
    }

    public void Stop()
    {
        if (watcher_ != null) {
            watcher_.EnableRaisingEvents = false;
            watcher_.Changed -= onChangedHandler_;
            watcher_.Created -= onChangedHandler_;
            watcher_.Deleted -= onChangedHandler_;
            watcher_.Renamed -= onRenamedHandler_;
        }
    }

    public void Update()
    {
        if (hasChanged_) {
            hasChanged_ = false;
            onChanged.Invoke();
        }
    }

    void OnChanged(object source, FileSystemEventArgs e)
    {
        hasChanged_ = true;
    }

    void OnRenamed(object source, RenamedEventArgs e)
    {
        hasChanged_ = true;
    }
}

}