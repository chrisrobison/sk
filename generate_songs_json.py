import argparse, glob, json, os, re
from collections import defaultdict

def parse_song_dir(path):
    info = {}
    base = os.path.basename(path)
    m = re.match(r'(\d{1,2})[-_](.+)', base)
    if m:
        info['track'] = int(m.group(1))
        title = m.group(2)
    else:
        title = base
    info['title'] = title.replace('_', ' ').replace('-', ' ')
    info['folder'] = path
    # detect optional assets deviating from defaults
    if not os.path.exists(os.path.join(path, 'karaoke.mp4')):
        if os.path.exists(os.path.join(path, 'karaoke.mp4')) is False:
            info['karaoke'] = None
    stems = {}
    stem_dir = os.path.join(path, 'stems')
    if os.path.isdir(stem_dir):
        for f in os.listdir(stem_dir):
            if f.endswith('.wav'):
                name = f.rsplit('.', 1)[0]
                default = f'{name}.wav'
                if f != default:
                    stems[name] = os.path.join('stems', f)
    if stems:
        info['stems'] = stems
    return info

def main():
    parser = argparse.ArgumentParser(description='Generate songs.json for TraqLab')
    parser.add_argument('patterns', nargs='+', help='Glob patterns to search for song files (e.g. albums/*/*/song.mp3)')
    parser.add_argument('-o', '--output', default='traqlab/songs.json', help='Output JSON file path')
    args = parser.parse_args()

    albums = defaultdict(list)
    for pattern in args.patterns:
        for file in glob.glob(pattern):
            song_dir = os.path.dirname(file)
            album_dir = os.path.dirname(song_dir)
            album_key = os.path.relpath(album_dir)
            info = parse_song_dir(os.path.relpath(song_dir))
            albums[album_key].append(info)

    result = {'albums': []}
    for album_dir in sorted(albums.keys()):
        title = os.path.basename(album_dir).replace('_', ' ')
        songs = sorted(albums[album_dir], key=lambda x: x.get('track', 0))
        result['albums'].append({'title': title, 'path': album_dir, 'songs': songs})

    with open(args.output, 'w') as f:
        json.dump(result, f, indent=2)

if __name__ == '__main__':
    main()
