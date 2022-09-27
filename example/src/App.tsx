import * as React from 'react';

import { SafeAreaView, ScrollView, Share } from 'react-native';
import {
  BonjourService,
  getUrlSchemes,
  hasNotSwitched,
  supportsLocalDevelopment,
  switchToPackager,
} from 'komondor';
import { List, ListItem } from './Components/List';
import { tw } from './tw';
import { useDeviceContext } from 'twrnc';
import { StarButton } from './StarButton';
import { useHandleUrl } from './lib/useHandleUrl';
import { parseAppUrl } from './lib/parseAppUrl';
import { useAsyncMemo } from './lib/useAsyncMemo';
import { useKnownPackagers } from './lib/useKnownPackagers';
import { useAsyncEffect } from './lib/useAsyncEffect';
import { useBonjourScan } from './lib/useBonjourScan';
import { getShortRepoName } from './lib/getShortRepoName';

export default function App() {
  useDeviceContext(tw);

  const [requestedPackager, setRequestedPackager] = React.useState<string>();

  useHandleUrl((url) => {
    const urlAction = parseAppUrl(url);

    if (urlAction?.action === 'switch-to-host') {
      setRequestedPackager(urlAction.host);
    }
  });

  const urlSchemes = useAsyncMemo(getUrlSchemes, [], []);
  const isDevMachine = useAsyncMemo(supportsLocalDevelopment, [], false);
  const isInitialRun = useAsyncMemo(hasNotSwitched, [], false);

  const { favoritePackagers, toggleFavoritePackager } = useKnownPackagers();

  const watchedPackagers = React.useMemo(
    () => [
      ...(isInitialRun && isDevMachine ? ['localhost:8081'] : []),
      ...(isInitialRun ? favoritePackagers : []),
      ...(requestedPackager ? [requestedPackager] : []),
    ],
    [isDevMachine, isInitialRun, favoritePackagers, requestedPackager]
  );

  const services = useBonjourScan();

  useAsyncEffect(async () => {
    const pickedService = services.find((s) =>
      watchedPackagers.includes(s.name)
    );

    if (pickedService !== undefined) {
      switchToPackager(
        `${pickedService.addresses[0]}:${pickedService.port}`
      ).catch((exception) => console.log(exception));
    }
  }, [services, watchedPackagers]);

  const packagerItems: (ListItem & { service: BonjourService })[] =
    React.useMemo(
      () =>
        services.map((service) => {
          return {
            title: service.name,
            subtitle: [
              getShortRepoName(service.txt.repo ?? ''),
              '>',
              service.txt.branch,
            ].join(' '),
            service,
            accessoryItem: (
              <StarButton
                starred={favoritePackagers.includes(service.name)}
                style={tw`mr-2`}
                onPress={() => toggleFavoritePackager(service.name)}
              />
            ),
          };
        }),
      [services, favoritePackagers, toggleFavoritePackager]
    );

  return (
    <SafeAreaView style={tw`bg-slate-200 dark:bg-slate-700`}>
      <ScrollView style={tw`w-full h-full p-3 `}>
        <List
          header="Running Packagers"
          items={packagerItems}
          onPress={({ service }) => {
            switchToPackager(`${service.addresses[0]}:${service.port}`).catch(
              (exception) => console.log(exception)
            );
          }}
        />
        <List
          header="URL Schemes"
          items={urlSchemes.map((title) => ({ title }))}
          onPress={({ title }) => Share.share({ message: title })}
        />
      </ScrollView>
    </SafeAreaView>
  );
}
