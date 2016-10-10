using System.IO;

namespace Raymarching
{

public class FileWatcher
{
    FileSystemWatcher watcher_;

    public delegate void OnChangeEvent();
    public event OnChangeEvent onChange;
    bool hasChanged_ = false;

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

        watcher_.Changed += new FileSystemEventHandler(OnChanged);
        watcher_.Created += new FileSystemEventHandler(OnChanged);
        watcher_.Deleted += new FileSystemEventHandler(OnChanged);
        watcher_.Renamed += new RenamedEventHandler(OnRenamed);

        watcher_.EnableRaisingEvents = true;
    }

    public void Stop()
    {
        if (watcher_ != null) {
            watcher_.EnableRaisingEvents = false;
        }
    }

    public void Update()
    {
        if (hasChanged_) {
            hasChanged_ = false;
            onChange();
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