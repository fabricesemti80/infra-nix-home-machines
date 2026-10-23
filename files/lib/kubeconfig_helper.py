#!/usr/bin/env python3
"""Import/retire local kubeconfig entries, inspired by TechDufus/dotfiles.

Uses kubectl only to flatten file references and parse YAML, never to contact a
cluster. Writes JSON (valid kubeconfig), with a private backup and atomic replace.
"""
import argparse
import copy
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


def load(path):
    result = subprocess.run(
        ['kubectl', '--kubeconfig', str(path), 'config', 'view', '--raw',
         '--flatten', '-o', 'json'], check=True, capture_output=True, text=True)
    config = json.loads(result.stdout)
    for section in ('clusters', 'contexts', 'users'):
        config[section] = config.get(section) or []
    return config


def empty():
    return {'apiVersion': 'v1', 'kind': 'Config', 'clusters': [],
            'contexts': [], 'users': [], 'current-context': ''}


def entry(config, section, name):
    matches = [x for x in config.get(section, []) if x['name'] == name]
    if len(matches) != 1:
        raise ValueError(f'Expected exactly one {section} entry named {name!r}')
    return copy.deepcopy(matches[0])


def import_context(dest, source, name, context=None, server=None):
    source = copy.deepcopy(source)
    contexts = source.get('contexts', [])
    selected = context or source.get('current-context')
    if not selected and len(contexts) == 1:
        selected = contexts[0]['name']
    ctx = entry(source, 'contexts', selected)
    cluster = entry(source, 'clusters', ctx['context']['cluster'])
    user_name = ctx['context'].get('user')
    user = entry(source, 'users', user_name) if user_name else None
    if server:
        if not server.startswith('https://'):
            raise ValueError('--server must start with https://')
        cluster['cluster']['server'] = server
    additions = [('contexts', ctx), ('clusters', cluster)]
    if user:
        additions.append(('users', user))
    result = copy.deepcopy(dest)
    for section, item in additions:
        if any(x['name'] == name for x in result.get(section, [])):
            raise ValueError(f'{section} name {name!r} already exists; choose another name')
        item['name'] = name
        result.setdefault(section, []).append(item)
    ctx['context']['cluster'] = name
    if user:
        ctx['context']['user'] = name
    # Preserve the selected destination context; select the import only if unset.
    if not result.get('current-context'):
        result['current-context'] = name
    return result


def delete_cluster(config, name):
    entry(config, 'clusters', name)  # Fail instead of silently doing nothing.
    result = copy.deepcopy(config)
    removed = [x for x in result.get('contexts', [])
               if x['context'].get('cluster') == name]
    result['contexts'] = [x for x in result.get('contexts', [])
                          if x['context'].get('cluster') != name]
    result['clusters'] = [x for x in result['clusters'] if x['name'] != name]
    candidates = {x['context'].get('user') for x in removed}
    retained = {x['context'].get('user') for x in result['contexts']}
    result['users'] = [x for x in result.get('users', [])
                       if x['name'] not in candidates - retained]
    if result.get('current-context') in {x['name'] for x in removed}:
        result['current-context'] = ''
    return result, [x['name'] for x in removed]


def save(path, config, original):
    # Detect concurrent edits between reading, confirmation and writing.
    current = path.read_bytes() if path.exists() else None
    if current != original:
        raise ValueError('Destination changed while preparing update; retry')
    path.parent.mkdir(parents=True, exist_ok=True)
    backup = None
    if original is not None:
        fd, backup = tempfile.mkstemp(prefix=path.name + '.backup-', dir=path.parent)
        with os.fdopen(fd, 'wb') as stream:
            stream.write(original)
    fd, temporary = tempfile.mkstemp(prefix=path.name + '.tmp-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as stream:
            json.dump(config, stream, indent=2)
            stream.write('\n')
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    if backup:
        print(f'Backup: {backup}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--destination', '-d', type=Path,
                        help='Single destination file; defaults to KUBECONFIG or ~/.kube/config')
    commands = parser.add_subparsers(dest='command', required=True)
    imp = commands.add_parser('import', help='Import one context under a new name')
    imp.add_argument('--import', '-i', dest='source', type=Path, required=True)
    imp.add_argument('--new-name', '-n', required=True)
    imp.add_argument('--context', '-c')
    imp.add_argument('--server', help='Explicit HTTPS API endpoint override')
    delete = commands.add_parser('delete', help='Remove a cluster and its associated contexts')
    delete.add_argument('cluster')
    delete.add_argument('--yes', action='store_true', help='Skip confirmation')
    delete.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    raw_path = str(args.destination) if args.destination else os.environ.get(
        'KUBECONFIG', str(Path.home() / '.kube/config'))
    if not raw_path or os.pathsep in raw_path:
        raise ValueError('Use --destination with one file; kubeconfig lists are not writable targets')
    path = Path(raw_path).expanduser().resolve()
    original = path.read_bytes() if path.exists() else None
    config = load(path) if original is not None else empty()
    if args.command == 'import':
        source = args.source.expanduser().resolve(strict=True)
        if source == path:
            raise ValueError('Import source must differ from destination')
        if not args.new_name.strip():
            raise ValueError('New name must not be empty')
        result = import_context(config, load(source), args.new_name,
                                args.context, args.server)
    else:
        result, contexts = delete_cluster(config, args.cluster)
        print(f'Remove cluster {args.cluster!r}; contexts: {", ".join(contexts) or "none"}')
        if args.dry_run:
            return
        if not args.yes and input('Type yes to continue: ') != 'yes':
            print('Cancelled')
            return
    save(path, result, original)
    print(f'Updated: {path}')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError, EOFError) as exc:
        # Do not echo kubectl stdout: it can contain raw credentials.
        print(f'Error: {exc}', file=sys.stderr)
        sys.exit(1)
